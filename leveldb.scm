
(module leveldb 
  ;; Exported procedures:
  (leveldb-open
   leveldb-close
   leveldb-get
   leveldb-put
   leveldb-delete
   leveldb-options-create
   leveldb-options-destroy
   leveldb-options-set-create-if-missing
   leveldb-writeoptions-create
   leveldb-writeoptions-destroy
   leveldb-writeoptions-set-sync
   leveldb-readoptions-create
   leveldb-readoptions-destroy
   leveldb-readoptions-set-verify-checksums
   leveldb-readoptions-set-fill-cache)

  (import
    chicken     ; Standard import
    scheme      ; Standard import
    foreign)    ; For various C types and the following special forms:
                ;    foreign-lambda,
                ;    foreign-lambda*

  (foreign-declare "#include <leveldb_c.h>")

  (define-record dbhandle pointer)
  (define-record dboptions pointer)
  (define-record readoptions pointer)
  (define-record writeoptions pointer)
  (define-location errmsg c-string #f )

  ;;
  ;; DB Operations
  ;;

  (define (leveldb-close dbhandle)
    (let ((dbhandle* (dbhandle-pointer dbhandle)))
      (when dbhandle*
        ((foreign-lambda
           void 
           leveldb_close
           (c-pointer (struct "leveldb_t")))
         dbhandle*)
        (dbhandle-pointer-set! dbhandle #f))))


  (define (leveldb-open opts path)
    (let* ((dboptions* (dboptions-pointer opts))
          (dbhandle* ((foreign-lambda
                       (c-pointer (struct "leveldb_t")) ;; The return type of the C function 
                       leveldb_open                             ;; The name of the C function
                       (c-pointer (struct "leveldb_options_t")) ;; param 1
                       c-string                                 ;; param 2
                       (c-pointer c-string) )                   ;; param 3 (not passed from parent func)
            dboptions* path (location errmsg))))
      (if dbhandle*
        (set-finalizer! (make-dbhandle dbhandle*) leveldb-close)
        (error errmsg))))

  ;;
  ;;  Data operations
  ;;

  (define (leveldb-put db opts key val)
    (let ((writeoptions* (writeoptions-pointer opts))
         (dbhandle* (dbhandle-pointer db)))
      ((foreign-lambda
        void
        leveldb_put
        (c-pointer (struct "leveldb_t"))
        (c-pointer (struct "leveldb_writeoptions_t"))
        c-string
        unsigned-int
        c-string
        unsigned-int
        (c-pointer c-string))
      dbhandle* writeoptions* key (string-length key) val (string-length val) (location errmsg))
      (if errmsg 
        ((error errmsg) #f)
        #t
      )))
  
  (define (leveldb-delete db opts key)
    (let ((writeoptions* (writeoptions-pointer opts))
         (dbhandle* (dbhandle-pointer db)))
      ((foreign-lambda
        void
        leveldb_delete
        (c-pointer (struct "leveldb_t"))
        (c-pointer (struct "leveldb_writeoptions_t"))
        c-string
        unsigned-int
        (c-pointer c-string))
      dbhandle* writeoptions* key (string-length key) (location errmsg))
      (if errmsg 
        ((error errmsg) #f)
        #t
      )))
  
  (define-location vallen unsigned-int 0 )

  (define (leveldb-get db opts key)
    (let* ((readoptions* (readoptions-pointer opts))
         (dbhandle* (dbhandle-pointer db))
         (result* 
      ((foreign-lambda
        c-string 
        leveldb_get
        (c-pointer (struct "leveldb_t"))
        (c-pointer (struct "leveldb_readoptions_t"))
        c-string
        unsigned-int
        (c-pointer unsigned-int)
        (c-pointer c-string))
      dbhandle* readoptions* key (string-length key) (location vallen) (location errmsg))))
      (unless result* error errmsg)
      result*))
#|

 void leveldb_write(
    leveldb_t* db,
    const leveldb_writeoptions_t* options,
    leveldb_writebatch_t* batch,
    char** errptr);

 |#


  ;;
  ;; DB Level Options
  ;;
 
  (define (leveldb-options-destroy opts)
    (let ((dboptions* (dboptions-pointer opts)))
      (when dboptions*
        ((foreign-lambda
          void
          leveldb_options_destroy
          (c-pointer (struct "leveldb_options_t")))
        dboptions*)
        (dboptions-pointer-set! opts #f))))


  (define (leveldb-options-create) 
    (let ((dboptions* ((foreign-lambda
                        (c-pointer (struct "leveldb_options_t"))
                        leveldb_options_create))))
    (if dboptions*
      (set-finalizer! (make-dboptions dboptions*) leveldb-options-destroy)
      (error "Unable to construct a new Options object"))))

  (define (bool->char val) (if val #\x1 #\x0))

  (define (leveldb-options-set-create-if-missing opts val)
    (let ((dboptions* (dboptions-pointer opts)))
      ((foreign-lambda
        void
        leveldb_options_set_create_if_missing
        (c-pointer (struct "leveldb_options_t"))
        unsigned-char)
      dboptions* (bool->char val))))

  ;;
  ;; Data Get level options
  ;;
  
  (define (leveldb-readoptions-destroy opts)
    (let ((readoptions* (readoptions-pointer opts)))
      (when readoptions*
        ((foreign-lambda
          void
          leveldb_readoptions_destroy
          (c-pointer (struct "leveldb_readoptions_t")))
        readoptions*)
        (readoptions-pointer-set! opts #f))))

  (define (leveldb-readoptions-create) 
    (let ((readoptions* ((foreign-lambda
                        (c-pointer (struct "leveldb_readoptions_t"))
                        leveldb_readoptions_create))))
    (if readoptions*
      (set-finalizer! (make-readoptions readoptions*) leveldb-readoptions-destroy)
      (error "Unable to construct a new ReadOptions object"))))

  (define (leveldb-readoptions-set-verify-checksums opts val)
    (let ((readoptions* (readoptions-pointer opts)))
      ((foreign-lambda
        void
        leveldb_readoptions_set_verify_checksums
        (c-pointer (struct "leveldb_readoptions_t"))
        unsigned-char)
      readoptions* (bool->char val))))
     
  (define (leveldb-readoptions-set-fill-cache opts val)
    (let ((readoptions* (readoptions-pointer opts)))
      ((foreign-lambda
        void
        leveldb_readoptions_set_fill_cache
        (c-pointer (struct "leveldb_readoptions_t"))
        unsigned-char)
      readoptions* (bool->char val))))

    ;; TODO  leveldb_readoptions_set_snapshot

  ;;
  ;; Data Put level options
  ;;
  
  (define (leveldb-writeoptions-destroy opts)
    (let ((writeoptions* (writeoptions-pointer opts)))
      (when writeoptions*
        ((foreign-lambda
          void
          leveldb_writeoptions_destroy
          (c-pointer (struct "leveldb_writeoptions_t")))
        writeoptions*)
        (writeoptions-pointer-set! opts #f))))

  (define (leveldb-writeoptions-create) 
    (let ((writeoptions* ((foreign-lambda
                        (c-pointer (struct "leveldb_writeoptions_t"))
                        leveldb_writeoptions_create))))
    (if writeoptions*
      (set-finalizer! (make-writeoptions writeoptions*) leveldb-writeoptions-destroy)
      (error "Unable to construct a new WriteOptions object"))))

  (define (leveldb-writeoptions-set-sync opts val)
    (let ((writeoptions* (writeoptions-pointer opts)))
      ((foreign-lambda
        void
        leveldb_writeoptions_set_sync
        (c-pointer (struct "leveldb_writeoptions_t"))
        unsigned-char)
      writeoptions* (bool->char val))))


)
 
