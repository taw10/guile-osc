/*
 * guile-osc.c
 *
 * Copyright © 2023 Thomas White <taw@bitwiz.org.uk>
 *
 * This file is part of Guile-OSC.
 *
 * Guile-OSC is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <stdio.h>

#include <libguile.h>
#include <lo/lo.h>


static SCM osc_server_thread_type;
static SCM osc_method_type;
static SCM osc_address_type;


static void error_callback(int num, const char *msg, const char *path)
{
	fprintf(stderr, "liblo error %i (%s) for path %s\n", num, msg, path);
}


static SCM make_osc_server_thread(SCM url_obj)
{
	const char *url = scm_to_utf8_stringn(url_obj, NULL);
	lo_server_thread srv = lo_server_thread_new_from_url(url, error_callback);
	if ( srv == NULL ) {
		return SCM_BOOL_F;
	} else {
		lo_server_thread_start(srv);
		return scm_make_foreign_object_1(osc_server_thread_type, srv);
	}
}


static void finalize_osc_server_thread(SCM obj)
{
	lo_server_thread srv;
	scm_assert_foreign_object_type(osc_server_thread_type, obj);
	srv = scm_foreign_object_ref(obj, 0);
	lo_server_thread_free(srv);
}


static SCM make_osc_address(SCM url_obj)
{
	lo_address addr;
	const char *url = scm_to_utf8_stringn(url_obj, NULL);
	addr = lo_address_new_from_url(url);
	if ( addr == NULL ) {
		return SCM_BOOL_F;
	} else {
		return scm_make_foreign_object_1(osc_address_type, addr);
	}
}


static void finalize_osc_address(SCM addr_obj)
{
	lo_address addr;
	scm_assert_foreign_object_type(osc_address_type, addr_obj);
	addr = scm_foreign_object_ref(addr_obj, 0);
	lo_address_free(addr);
}


struct method_callback_data
{
	SCM proc;
};


/* This struct exists just to help get the method callback arguments
 * into Guile mode */
struct method_callback_guile_data
{
	const char *path;
	const char *types;
	lo_arg **argv;
	int argc;
	lo_message msg;
	SCM proc;
};


static void *method_callback_with_guile(void *vp)
{
	struct method_callback_guile_data *data = vp;
	SCM *args;

	if ( data->argc > 0) {

		int i;
		const char *types;

		args = malloc(sizeof(SCM)*data->argc);
		if ( args == NULL ) return NULL;

		types = lo_message_get_types(data->msg);

		for ( i=0; i<data->argc; i++ ) {
			switch ( types[i] ) {

				case LO_STRING:
				args[i] = scm_from_utf8_string(&data->argv[i]->s);
				break;

				case LO_SYMBOL:
				args[i] = scm_from_utf8_symbol(&data->argv[i]->S);
				break;

				case LO_INT32:
				args[i] = scm_from_int32(data->argv[i]->i32);
				break;

				case LO_INT64:
				args[i] = scm_from_int64(data->argv[i]->i64);
				break;

				case LO_FLOAT:
				args[i] = scm_from_double(data->argv[i]->f);
				break;

				case LO_DOUBLE:
				args[i] = scm_from_double(data->argv[i]->d);
				break;

				case LO_CHAR:
				args[i] = scm_from_uchar(data->argv[i]->c);
				break;

				case LO_TRUE:
				args[i] = SCM_BOOL_T;
				break;

				case LO_FALSE:
				args[i] = SCM_BOOL_F;
				break;

				case LO_NIL:
				args[i] = SCM_EOL;
				break;

				case LO_INFINITUM:
				args[i] = scm_inf();
				break;

				default:
				fprintf(stderr, "Unrecognised argument type '%c'\n",
				        types[i]);
				return NULL;

				/* Notable omissions so far: LO_TIMETAG and LO_BLOB */
			}
		}
	} else {
		args = NULL;
	}

	scm_call_n(data->proc, args, data->argc);
	free(args);
	return NULL;
}


static int method_callback(const char *path, const char *types, lo_arg **argv,
                           int argc, lo_message msg, void *vp)
{
	struct method_callback_data *data = vp;

	/* The OSC server thread is not under our control, and is not in
	 * Guile mode.  Therefore, some "tedious mucking-about in hyperspace"
	 * is required before we can invoke the Scheme callback */
	struct method_callback_guile_data cb_data;
	cb_data.path = path;
	cb_data.types = types;
	cb_data.argv = argv;
	cb_data.argc = argc;
	cb_data.msg = msg;
	cb_data.proc = data->proc;
	scm_with_guile(method_callback_with_guile, &cb_data);
	return 1;
}


static SCM add_osc_method(SCM server_obj, SCM path_obj, SCM argtypes_obj,
                          SCM proc)
{
	lo_server_thread srv;
	lo_method method;
	char *path;
	char *argtypes;
	struct method_callback_data *data;

	scm_assert_foreign_object_type(osc_server_thread_type, server_obj);
	srv = scm_foreign_object_ref(server_obj, 0);

	argtypes = scm_to_utf8_stringn(argtypes_obj, NULL);
	data = malloc(sizeof(struct method_callback_data));

	data->proc = proc;
	scm_gc_protect_object(proc);

	path = scm_to_utf8_stringn(path_obj, NULL);
	method = lo_server_thread_add_method(srv, path, argtypes,
	                                     method_callback, data);
	free(path);
	free(argtypes);

	return scm_make_foreign_object_1(osc_method_type, method);
}


static SCM osc_send(SCM addr_obj, SCM path_obj, SCM rest)
{
	lo_address addr;
	char *path;
	int n_args;
	lo_message message;
	int i;

	scm_assert_foreign_object_type(osc_address_type, addr_obj);
	addr = scm_foreign_object_ref(addr_obj, 0);
	path = scm_to_utf8_stringn(path_obj, NULL);

	n_args = scm_to_int(scm_length(rest));

	message = lo_message_new();
	for ( i=0; i<n_args; i++ ) {
		SCM item = scm_list_ref(rest, scm_from_int(i));

		if ( scm_is_true(scm_real_p(item)) ) {
			lo_message_add_double(message, scm_to_double(item));
		} else if ( scm_is_true(scm_integer_p(item)) ) {
			lo_message_add_int32(message, scm_to_int(item));
		} else if ( scm_is_true(scm_string_p(item)) ) {
			lo_message_add_string(message, scm_to_utf8_stringn(item, NULL));
		} else if ( scm_is_true(scm_symbol_p(item)) ) {
			lo_message_add_symbol(message,
			                      scm_to_utf8_stringn(scm_symbol_to_string(item),
			                                          NULL));
		} else {
			fprintf(stderr, "Unrecognised type\n");
		}
	}

	lo_send_message(addr, path, message);
	lo_message_free(message);

	return SCM_UNSPECIFIED;
}


void init_guile_osc()
{
	SCM name, slots;

	name = scm_from_utf8_symbol("OSCServerThread");
	slots = scm_list_1(scm_from_utf8_symbol("data"));
	osc_server_thread_type = scm_make_foreign_object_type(name,
	                                                      slots,
	                                                      finalize_osc_server_thread);

	name = scm_from_utf8_symbol("OSCMethod");
	slots = scm_list_1(scm_from_utf8_symbol("data"));
	osc_method_type = scm_make_foreign_object_type(name, slots, NULL);

	name = scm_from_utf8_symbol("OSCAddress");
	slots = scm_list_1(scm_from_utf8_symbol("data"));
	osc_address_type = scm_make_foreign_object_type(name, slots, finalize_osc_address);

	scm_c_define_gsubr("make-osc-server-thread", 1, 0, 0, make_osc_server_thread);
	scm_c_define_gsubr("add-osc-method", 4, 0, 0, add_osc_method);
	scm_c_define_gsubr("make-osc-address", 1, 0, 0, make_osc_address);
	scm_c_define_gsubr("osc-send", 2, 0, 1, osc_send);

	scm_add_feature("guile-osc");
}
