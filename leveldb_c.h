/* Copyright (c) 2011 The LevelDB Authors. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file. See the AUTHORS file for names of contributors.

  C bindings for leveldb.  May be useful as a stable ABI that can be
  used by programs that keep leveldb in a shared library, or for
  a JNI api.

  Does not support:
  . getters for the option types
  . custom comparators that implement key shortening
  . capturing post-write-snapshot
  . custom iter, db, env, cache implementations using just the C bindings

  Some conventions:

  (1) We expose just opaque struct pointers and functions to clients.
  This allows us to change internal representations without having to
  recompile clients.

  (2) For simplicity, there is no equivalent to the Slice type.  Instead,
  the caller has to pass the pointer and length as separate
  arguments.

  (3) Errors are represented by a null-terminated c string.  NULL
  means no error.  All operations that can raise an error are passed
  a "char** errptr" as the last argument.  One of the following must
  be true on entry:
     *errptr == NULL
     *errptr points to a malloc()ed null-terminated error message
  On success, a leveldb routine leaves *errptr unchanged.
  On failure, leveldb frees the old value of *errptr and
  set *errptr to a malloc()ed error message.

  (4) Bools have the type unsigned char (0 == false; rest == true)

  (5) All of the pointer arguments must be non-NULL.
*/

#ifndef STORAGE_LEVELDB_INCLUDE_C_H_
#define STORAGE_LEVELDB_INCLUDE_C_H_

#ifdef __cplusplus
 extern "C" {
#endif

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

/* Exported types */

typedef struct leveldb_t               leveldb_t;
typedef struct leveldb_cache_t         leveldb_cache_t;
typedef struct leveldb_comparator_t    leveldb_comparator_t;
typedef struct leveldb_env_t           leveldb_env_t;
typedef struct leveldb_filelock_t      leveldb_filelock_t;
typedef struct leveldb_iterator_t      leveldb_iterator_t;
typedef struct leveldb_logger_t        leveldb_logger_t;
typedef struct leveldb_options_t       leveldb_options_t;
typedef struct leveldb_randomfile_t    leveldb_randomfile_t;
typedef struct leveldb_readoptions_t   leveldb_readoptions_t;
typedef struct leveldb_seqfile_t       leveldb_seqfile_t;
typedef struct leveldb_snapshot_t      leveldb_snapshot_t;
typedef struct leveldb_writablefile_t  leveldb_writablefile_t;
typedef struct leveldb_writebatch_t    leveldb_writebatch_t;
typedef struct leveldb_writeoptions_t  leveldb_writeoptions_t;

/* DB operations */

 leveldb_t* leveldb_open(
    const leveldb_options_t* options,
    const char* name,
    char** errptr);

 void leveldb_close(leveldb_t* db);

 void leveldb_put(
    leveldb_t* db,
    const leveldb_writeoptions_t* options,
    const char* key, unsigned int keylen,
    const char* val, unsigned int vallen,
    char** errptr);

 void leveldb_delete(
    leveldb_t* db,
    const leveldb_writeoptions_t* options,
    const char* key, unsigned int keylen,
    char** errptr);

 void leveldb_write(
    leveldb_t* db,
    const leveldb_writeoptions_t* options,
    leveldb_writebatch_t* batch,
    char** errptr);

/* Returns NULL if not found.  A malloc()ed array otherwise.
   Stores the length of the array in *vallen. */
 char* leveldb_get(
    leveldb_t* db,
    const leveldb_readoptions_t* options,
    const char* key, unsigned int keylen,
    unsigned int* vallen,
    char** errptr);

 leveldb_iterator_t* leveldb_create_iterator(
    leveldb_t* db,
    const leveldb_readoptions_t* options);

 const leveldb_snapshot_t* leveldb_create_snapshot(
    leveldb_t* db);

 void leveldb_release_snapshot(
    leveldb_t* db,
    const leveldb_snapshot_t* snapshot);

/* Returns NULL if property name is unknown.
   Else returns a pointer to a malloc()-ed null-terminated value. */
 char* leveldb_property_value(
    leveldb_t* db,
    const char* propname);

 void leveldb_approximate_sizes(
    leveldb_t* db,
    int num_ranges,
    const char* const* range_start_key, const unsigned int* range_start_key_len,
    const char* const* range_limit_key, const unsigned int* range_limit_key_len,
    uint64_t* sizes);

/* Management operations */

 void leveldb_destroy_db(
    const leveldb_options_t* options,
    const char* name,
    char** errptr);

 void leveldb_repair_db(
    const leveldb_options_t* options,
    const char* name,
    char** errptr);

/* Iterator */

 void leveldb_iter_destroy(leveldb_iterator_t*);
 unsigned char leveldb_iter_valid(const leveldb_iterator_t*);
 void leveldb_iter_seek_to_first(leveldb_iterator_t*);
 void leveldb_iter_seek_to_last(leveldb_iterator_t*);
 void leveldb_iter_seek(leveldb_iterator_t*, const char* k, unsigned int klen);
 void leveldb_iter_next(leveldb_iterator_t*);
 void leveldb_iter_prev(leveldb_iterator_t*);
 const char* leveldb_iter_key(const leveldb_iterator_t*, unsigned int* klen);
 const char* leveldb_iter_value(const leveldb_iterator_t*, unsigned int* vlen);
 void leveldb_iter_get_error(const leveldb_iterator_t*, char** errptr);

/* Write batch */

 leveldb_writebatch_t* leveldb_writebatch_create();
 void leveldb_writebatch_destroy(leveldb_writebatch_t*);
 void leveldb_writebatch_clear(leveldb_writebatch_t*);
 void leveldb_writebatch_put(
    leveldb_writebatch_t*,
    const char* key, unsigned int klen,
    const char* val, unsigned int vlen);
 void leveldb_writebatch_delete(
    leveldb_writebatch_t*,
    const char* key, unsigned int klen);
 void leveldb_writebatch_iterate(
    leveldb_writebatch_t*,
    void* state,
    void (*put)(void*, const char* k, unsigned int klen, const char* v, unsigned int vlen),
    void (*deleted)(void*, const char* k, unsigned int klen));

/* Options */

 leveldb_options_t* leveldb_options_create();
 void leveldb_options_destroy(leveldb_options_t*);
 void leveldb_options_set_comparator(
    leveldb_options_t*,
    leveldb_comparator_t*);
 void leveldb_options_set_create_if_missing(
    leveldb_options_t*, unsigned char);
 void leveldb_options_set_error_if_exists(
    leveldb_options_t*, unsigned char);
 void leveldb_options_set_paranoid_checks(
    leveldb_options_t*, unsigned char);
 void leveldb_options_set_env(leveldb_options_t*, leveldb_env_t*);
 void leveldb_options_set_info_log(leveldb_options_t*, leveldb_logger_t*);
 void leveldb_options_set_write_buffer_size(leveldb_options_t*, unsigned int);
 void leveldb_options_set_max_open_files(leveldb_options_t*, int);
 void leveldb_options_set_cache(leveldb_options_t*, leveldb_cache_t*);
 void leveldb_options_set_block_size(leveldb_options_t*, unsigned int);
 void leveldb_options_set_block_restart_interval(leveldb_options_t*, int);

enum {
  leveldb_no_compression = 0,
  leveldb_snappy_compression = 1
};
 void leveldb_options_set_compression(leveldb_options_t*, int);

/* Comparator */

 leveldb_comparator_t* leveldb_comparator_create(
    void* state,
    void (*destructor)(void*),
    int (*compare)(
        void*,
        const char* a, unsigned int alen,
        const char* b, unsigned int blen),
    const char* (*name)(void*));
 void leveldb_comparator_destroy(leveldb_comparator_t*);

/* Read options */

 leveldb_readoptions_t* leveldb_readoptions_create();
 void leveldb_readoptions_destroy(leveldb_readoptions_t*);
 void leveldb_readoptions_set_verify_checksums(
    leveldb_readoptions_t*,
    unsigned char);
 void leveldb_readoptions_set_fill_cache(
    leveldb_readoptions_t*, unsigned char);
 void leveldb_readoptions_set_snapshot(
    leveldb_readoptions_t*,
    const leveldb_snapshot_t*);

/* Write options */

 leveldb_writeoptions_t* leveldb_writeoptions_create();
 void leveldb_writeoptions_destroy(leveldb_writeoptions_t*);
 void leveldb_writeoptions_set_sync(
    leveldb_writeoptions_t*, unsigned char);

/* Cache */

 leveldb_cache_t* leveldb_cache_create_lru(unsigned int capacity);
 void leveldb_cache_destroy(leveldb_cache_t* cache);

/* Env */

 leveldb_env_t* leveldb_create_default_env();
 void leveldb_env_destroy(leveldb_env_t*);

#ifdef __cplusplus
}  /* end extern  "C" */
#endif

#endif  /* STORAGE_LEVELDB_INCLUDE_C_H_ */
