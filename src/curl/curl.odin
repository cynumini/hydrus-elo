package curl

import "core:c"

foreign import lib "system:libcurl.so"

CURL :: rawptr

GLOBAL_SSL: c.long : 1 << 0 /* no purpose since 7.57.0 */
GLOBAL_WIN32: c.long : 1 << 1
GLOBAL_ALL: c.long : GLOBAL_SSL | GLOBAL_WIN32

Code :: enum c.int {
	E_OK = 0,
	E_UNSUPPORTED_PROTOCOL, /* 1 */
	E_FAILED_INIT, /* 2 */
	E_URL_MALFORMAT, /* 3 */
	E_NOT_BUILT_IN, /* 4 - [was obsoleted in August 2007 for
                                    7.17.0, reused in April 2011 for 7.21.5] */
	E_COULDNT_RESOLVE_PROXY, /* 5 */
	E_COULDNT_RESOLVE_HOST, /* 6 */
	E_COULDNT_CONNECT, /* 7 */
	E_WEIRD_SERVER_REPLY, /* 8 */
	E_REMOTE_ACCESS_DENIED, /* 9 a service was denied by the server
                                    due to lack of access - when login fails
                                    this is not returned. */
	E_FTP_ACCEPT_FAILED, /* 10 - [was obsoleted in April 2006 for
                                    7.15.4, reused in Dec 2011 for 7.24.0]*/
	E_FTP_WEIRD_PASS_REPLY, /* 11 */
	E_FTP_ACCEPT_TIMEOUT, /* 12 - timeout occurred accepting server
                                    [was obsoleted in August 2007 for 7.17.0,
                                    reused in Dec 2011 for 7.24.0]*/
	E_FTP_WEIRD_PASV_REPLY, /* 13 */
	E_FTP_WEIRD_227_FORMAT, /* 14 */
	E_FTP_CANT_GET_HOST, /* 15 */
	E_HTTP2, /* 16 - A problem in the http2 framing layer.
                                    [was obsoleted in August 2007 for 7.17.0,
                                    reused in July 2014 for 7.38.0] */
	E_FTP_COULDNT_SET_TYPE, /* 17 */
	E_PARTIAL_FILE, /* 18 */
	E_FTP_COULDNT_RETR_FILE, /* 19 */
	E_OBSOLETE20, /* 20 - NOT USED */
	E_QUOTE_ERROR, /* 21 - quote command failure */
	E_HTTP_RETURNED_ERROR, /* 22 */
	E_WRITE_ERROR, /* 23 */
	E_OBSOLETE24, /* 24 - NOT USED */
	E_UPLOAD_FAILED, /* 25 - failed upload "command" */
	E_READ_ERROR, /* 26 - could not open/read from file */
	E_OUT_OF_MEMORY, /* 27 */
	E_OPERATION_TIMEDOUT, /* 28 - the timeout time was reached */
	E_OBSOLETE29, /* 29 - NOT USED */
	E_FTP_PORT_FAILED, /* 30 - FTP PORT operation failed */
	E_FTP_COULDNT_USE_REST, /* 31 - the REST command failed */
	E_OBSOLETE32, /* 32 - NOT USED */
	E_RANGE_ERROR, /* 33 - RANGE "command" did not work */
	E_OBSOLETE34, /* 34 */
	E_SSL_CONNECT_ERROR, /* 35 - wrong when connecting with SSL */
	E_BAD_DOWNLOAD_RESUME, /* 36 - could not resume download */
	E_FILE_COULDNT_READ_FILE, /* 37 */
	E_LDAP_CANNOT_BIND, /* 38 */
	E_LDAP_SEARCH_FAILED, /* 39 */
	E_OBSOLETE40, /* 40 - NOT USED */
	E_OBSOLETE41, /* 41 - NOT USED starting with 7.53.0 */
	E_ABORTED_BY_CALLBACK, /* 42 */
	E_BAD_FUNCTION_ARGUMENT, /* 43 */
	E_OBSOLETE44, /* 44 - NOT USED */
	E_INTERFACE_FAILED, /* 45 - CURLOPT_INTERFACE failed */
	E_OBSOLETE46, /* 46 - NOT USED */
	E_TOO_MANY_REDIRECTS, /* 47 - catch endless re-direct loops */
	E_UNKNOWN_OPTION, /* 48 - User specified an unknown option */
	E_SETOPT_OPTION_SYNTAX, /* 49 - Malformed setopt option */
	E_OBSOLETE50, /* 50 - NOT USED */
	E_OBSOLETE51, /* 51 - NOT USED */
	E_GOT_NOTHING, /* 52 - when this is a specific error */
	E_SSL_ENGINE_NOTFOUND, /* 53 - SSL crypto engine not found */
	E_SSL_ENGINE_SETFAILED, /* 54 - can not set SSL crypto engine as
                                    default */
	E_SEND_ERROR, /* 55 - failed sending network data */
	E_RECV_ERROR, /* 56 - failure in receiving network data */
	E_OBSOLETE57, /* 57 - NOT IN USE */
	E_SSL_CERTPROBLEM, /* 58 - problem with the local certificate */
	E_SSL_CIPHER, /* 59 - could not use specified cipher */
	E_PEER_FAILED_VERIFICATION, /* 60 - peer's certificate or fingerprint
                                     was not verified fine */
	E_BAD_CONTENT_ENCODING, /* 61 - Unrecognized/bad encoding */
	E_OBSOLETE62, /* 62 - NOT IN USE since 7.82.0 */
	E_FILESIZE_EXCEEDED, /* 63 - Maximum file size exceeded */
	E_USE_SSL_FAILED, /* 64 - Requested FTP SSL level failed */
	E_SEND_FAIL_REWIND, /* 65 - Sending the data requires a rewind
                                    that failed */
	E_SSL_ENGINE_INITFAILED, /* 66 - failed to initialise ENGINE */
	E_LOGIN_DENIED, /* 67 - user, password or similar was not
                                    accepted and we failed to login */
	E_TFTP_NOTFOUND, /* 68 - file not found on server */
	E_TFTP_PERM, /* 69 - permission problem on server */
	E_REMOTE_DISK_FULL, /* 70 - out of disk space on server */
	E_TFTP_ILLEGAL, /* 71 - Illegal TFTP operation */
	E_TFTP_UNKNOWNID, /* 72 - Unknown transfer ID */
	E_REMOTE_FILE_EXISTS, /* 73 - File already exists */
	E_TFTP_NOSUCHUSER, /* 74 - No such user */
	E_OBSOLETE75, /* 75 - NOT IN USE since 7.82.0 */
	E_OBSOLETE76, /* 76 - NOT IN USE since 7.82.0 */
	E_SSL_CACERT_BADFILE, /* 77 - could not load CACERT file, missing
                                    or wrong format */
	E_REMOTE_FILE_NOT_FOUND, /* 78 - remote file not found */
	E_SSH, /* 79 - error from the SSH layer, somewhat
                                    generic so the error message will be of
                                    interest when this has happened */
	E_SSL_SHUTDOWN_FAILED, /* 80 - Failed to shut down the SSL
                                    connection */
	E_AGAIN, /* 81 - socket is not ready for send/recv,
                                    wait till it is ready and try again (Added
                                    in 7.18.2) */
	E_SSL_CRL_BADFILE, /* 82 - could not load CRL file, missing or
                                    wrong format (Added in 7.19.0) */
	E_SSL_ISSUER_ERROR, /* 83 - Issuer check failed.  (Added in
                                    7.19.0) */
	E_FTP_PRET_FAILED, /* 84 - a PRET command failed */
	E_RTSP_CSEQ_ERROR, /* 85 - mismatch of RTSP CSeq numbers */
	E_RTSP_SESSION_ERROR, /* 86 - mismatch of RTSP Session Ids */
	E_FTP_BAD_FILE_LIST, /* 87 - unable to parse FTP file list */
	E_CHUNK_FAILED, /* 88 - chunk callback reported error */
	E_NO_CONNECTION_AVAILABLE, /* 89 - No connection available, the
                                    session will be queued */
	E_SSL_PINNEDPUBKEYNOTMATCH, /* 90 - specified pinned public key did not
                                     match */
	E_SSL_INVALIDCERTSTATUS, /* 91 - invalid certificate status */
	E_HTTP2_STREAM, /* 92 - stream error in HTTP/2 framing layer
                                    */
	E_RECURSIVE_API_CALL, /* 93 - an api function was called from
                                    inside a callback */
	E_AUTH_ERROR, /* 94 - an authentication function returned an
                                    error */
	E_HTTP3, /* 95 - An HTTP/3 layer problem */
	E_QUIC_CONNECT_ERROR, /* 96 - QUIC connection error */
	E_PROXY, /* 97 - proxy handshake error */
	E_SSL_CLIENTCERT, /* 98 - client-side certificate required */
	E_UNRECOVERABLE_POLL, /* 99 - poll/select returned fatal error */
	E_TOO_LARGE, /* 100 - a value/data met its maximum */
	E_ECH_REQUIRED, /* 101 - ECH tried but failed */
	_LAST, /* never use! */
	E_RESERVED115 = 115, /* 115-126 - used in tests */
	E_RESERVED116 = 116,
	E_RESERVED117 = 117,
	E_RESERVED118 = 118,
	E_RESERVED119 = 119,
	E_RESERVED120 = 120,
	E_RESERVED121 = 121,
	E_RESERVED122 = 122,
	E_RESERVED123 = 123,
	E_RESERVED124 = 124,
	E_RESERVED125 = 125,
	E_RESERVED126 = 126,
}

/*
* All CURLOPT_* values.
*/
Option :: enum c.int {
	WRITEDATA = 10001, /* This is the FILE * or void * the regular output should be written to. */
	URL = 10002, /* The full URL to get/put */
	PORT = 3, /* Port number to connect to, if other than default. */
	PROXY = 10004, /* Name of proxy to use. */
	USERPWD = 10005, /* "user:password;options" to use when fetching. */
	PROXYUSERPWD = 10006, /* "user:password" to use with proxy. */
	RANGE = 10007, /* Range to get, specified as an ASCII string. */
	READDATA = 10009, /* Specified file stream to upload from (use as input): */
	ERRORBUFFER = 10010, /* Buffer to receive error messages in, must be at least CURL_ERROR_SIZE
   * bytes big. */
	WRITEFUNCTION = 20011, /* Function that will be called to store the output (instead of fwrite). The
   * parameters will use fwrite() syntax, make sure to follow them. */
	READFUNCTION = 20012, /* Function that will be called to read the input (instead of fread). The
   * parameters will use fread() syntax, make sure to follow them. */
	TIMEOUT = 13, /* Time-out the read operation after this amount of seconds */
	INFILESIZE = 14, /* If CURLOPT_READDATA is used, this can be used to inform libcurl about
   * how large the file being sent really is. That allows better error
   * checking and better verifies that the upload was successful. -1 means
   * unknown size.
   *
   * For large file support, there is also a _LARGE version of the key
   * which takes an off_t type, allowing platforms with larger off_t
   * sizes to handle larger files. See below for INFILESIZE_LARGE.
   */
	POSTFIELDS = 10015, /* POST static input fields. */
	REFERER = 10016, /* Set the referrer page (needed by some CGIs) */
	FTPPORT = 10017, /* Set the FTP PORT string (interface name, named or numerical IP address)
     Use i.e '-' to use default address. */
	USERAGENT = 10018, /* Set the User-Agent string (examined by some CGIs) */
	LOW_SPEED_LIMIT = 19, /* Set the "low speed limit" */
	LOW_SPEED_TIME = 20, /* Set the "low speed time" */
	RESUME_FROM = 21, /* Set the continuation offset.
   *
   * Note there is also a _LARGE version of this key which uses
   * off_t types, allowing for large file offsets on platforms which
   * use larger-than-32-bit off_t's. Look below for RESUME_FROM_LARGE.
   */
	COOKIE = 10022, /* Set cookie in request: */
	HTTPHEADER = 10023, /* This points to a linked list of headers, struct curl_slist kind. This
     list is also used for RTSP (in spite of its name) */
	HTTPPOST = 10024, /* This points to a linked list of post entries, struct curl_httppost */
	SSLCERT = 10025, /* name of the file keeping your private SSL-certificate */
	KEYPASSWD = 10026, /* password for the SSL or SSH private key */
	CRLF = 27, /* send TYPE parameter? */
	QUOTE = 10028, /* send linked-list of QUOTE commands */
	HEADERDATA = 10029, /* send FILE * or void * to store headers to, if you use a callback it
     is simply passed to the callback unmodified */
	COOKIEFILE = 10031, /* point to a file to read the initial cookies from, also enables
     "cookie awareness" */
	SSLVERSION = 32, /* What version to specifically try to use.
     See CURL_SSLVERSION defines below. */
	TIMECONDITION = 33, /* What kind of HTTP time condition to use, see defines */
	TIMEVALUE = 34, /* Time to use with the above condition. Specified in number of seconds
     since 1 Jan 1970 */
	CUSTOMREQUEST = 10036, /* Custom request, for customizing the get command like
     HTTP: DELETE, TRACE and others
     FTP: to use a different list command
     */
	STDERR = 10037, /* FILE handle to use instead of stderr */
	POSTQUOTE = 10039, /* send linked-list of post-transfer QUOTE commands */
	VERBOSE = 41, /* talk a lot */
	HEADER = 42, /* throw the header out too */
	NOPROGRESS = 43, /* shut off the progress meter */
	NOBODY = 44, /* use HEAD to get http document */
	FAILONERROR = 45, /* no output on http error codes >= 400 */
	UPLOAD = 46, /* this is an upload */
	POST = 47, /* HTTP POST method */
	DIRLISTONLY = 48, /* bare names when listing directories */
	APPEND = 50, /* Append instead of overwrite on upload! */
	NETRC = 51, /* Specify whether to read the user+password from the .netrc or the URL.
   * This must be one of the CURL_NETRC_* enums below. */
	FOLLOWLOCATION = 52, /* use Location: Luke! */
	TRANSFERTEXT = 53, /* transfer data in text/ASCII format */
	PUT = 54, /* HTTP PUT */
	PROGRESSFUNCTION = 20056, /* DEPRECATED
   * Function that will be called instead of the internal progress display
   * function. This function should be defined as the curl_progress_callback
   * prototype defines. */
	XFERINFODATA = 10057, /* Data passed to the CURLOPT_PROGRESSFUNCTION and CURLOPT_XFERINFOFUNCTION
     callbacks */
	AUTOREFERER = 58, /* We want the referrer field set automatically when following locations */
	PROXYPORT = 59, /* Port of the proxy, can be set in the proxy string as well with:
     "[host]:[port]" */
	POSTFIELDSIZE = 60, /* size of the POST input data, if strlen() is not good to use */
	HTTPPROXYTUNNEL = 61, /* tunnel non-http operations through an HTTP proxy */
	INTERFACE = 10062, /* Set the interface string to use as outgoing network interface */
	KRBLEVEL = 10063, /* Set the krb4/5 security level, this also enables krb4/5 awareness. This
   * is a string, 'clear', 'safe', 'confidential' or 'private'. If the string
   * is set but does not match one of these, 'private' will be used.  */
	SSL_VERIFYPEER = 64, /* Set if we should verify the peer in ssl handshake, set 1 to verify. */
	CAINFO = 10065, /* The CApath or CAfile used to validate the peer certificate
     this option is used only if SSL_VERIFYPEER is true */
	MAXREDIRS = 68, /* Maximum number of http redirects to follow */
	FILETIME = 69, /* Pass a long set to 1 to get the date of the requested document (if
     possible)! Pass a zero to shut it off. */
	TELNETOPTIONS = 10070, /* This points to a linked list of telnet options */
	MAXCONNECTS = 71, /* Max amount of cached alive connections */
	FRESH_CONNECT = 74, /* Set to explicitly use a new connection for the upcoming transfer.
     Do not use this unless you are absolutely sure of this, as it makes the
     operation slower and is less friendly for the network. */
	FORBID_REUSE = 75, /* Set to explicitly forbid the upcoming transfer's connection to be reused
     when done. Do not use this unless you are absolutely sure of this, as it
     makes the operation slower and is less friendly for the network. */
	RANDOM_FILE = 10076, /* Set to a filename that contains random data for libcurl to use to
     seed the random engine when doing SSL connects. */
	EGDSOCKET = 10077, /* Set to the Entropy Gathering Daemon socket pathname */
	CONNECTTIMEOUT = 78, /* Time-out connect operations after this amount of seconds, if connects are
     OK within this time, then fine... This only aborts the connect phase. */
	HEADERFUNCTION = 20079, /* Function that will be called to store headers (instead of fwrite). The
   * parameters will use fwrite() syntax, make sure to follow them. */
	HTTPGET = 80, /* Set this to force the HTTP request to get back to GET. Only really usable
     if POST, PUT or a custom request have been used first.
   */
	SSL_VERIFYHOST = 81, /* Set if we should verify the Common name from the peer certificate in ssl
   * handshake, set 1 to check existence, 2 to ensure that it matches the
   * provided hostname. */
	COOKIEJAR = 10082, /* Specify which filename to write all known cookies in after completed
     operation. Set filename to "-" (dash) to make it go to stdout. */
	SSL_CIPHER_LIST = 10083, /* Specify which TLS 1.2 (1.1, 1.0) ciphers to use */
	HTTP_VERSION = 84, /* Specify which HTTP version to use! This must be set to one of the
     CURL_HTTP_VERSION* enums set below. */
	FTP_USE_EPSV = 85, /* Specifically switch on or off the FTP engine's use of the EPSV command. By
     default, that one will always be attempted before the more traditional
     PASV command. */
	SSLCERTTYPE = 10086, /* type of the file keeping your SSL-certificate ("DER", "PEM", "ENG") */
	SSLKEY = 10087, /* name of the file keeping your private SSL-key */
	SSLKEYTYPE = 10088, /* type of the file keeping your private SSL-key ("DER", "PEM", "ENG") */
	SSLENGINE = 10089, /* crypto engine for the SSL-sub system */
	SSLENGINE_DEFAULT = 90, /* set the crypto engine for the SSL-sub system as default
     the param has no meaning...
   */
	DNS_USE_GLOBAL_CACHE = 91, /* Non-zero value means to use the global dns cache */
	/* DEPRECATED, do not use! */
	DNS_CACHE_TIMEOUT = 92, /* DNS cache timeout */
	PREQUOTE = 10093, /* send linked-list of pre-transfer QUOTE commands */
	DEBUGFUNCTION = 20094, /* set the debug function */
	DEBUGDATA = 10095, /* set the data for the debug function */
	COOKIESESSION = 96, /* mark this as start of a cookie session */
	CAPATH = 10097, /* The CApath directory used to validate the peer certificate
     this option is used only if SSL_VERIFYPEER is true */
	BUFFERSIZE = 98, /* Instruct libcurl to use a smaller receive buffer */
	NOSIGNAL = 99, /* Instruct libcurl to not use any signal/alarm handlers, even when using
     timeouts. This option is useful for multi-threaded applications.
     See libcurl-the-guide for more background information. */
	SHARE = 10100, /* Provide a CURLShare for mutexing non-ts data */
	PROXYTYPE = 101, /* indicates type of proxy. accepted values are CURLPROXY_HTTP (default),
     CURLPROXY_HTTPS, CURLPROXY_SOCKS4, CURLPROXY_SOCKS4A and
     CURLPROXY_SOCKS5. */
	ACCEPT_ENCODING = 10102, /* Set the Accept-Encoding string. Use this to tell a server you would like
     the response to be compressed. Before 7.21.6, this was known as
     CURLOPT_ENCODING */
	PRIVATE = 10103, /* Set pointer to private data */
	HTTP200ALIASES = 10104, /* Set aliases for HTTP 200 in the HTTP Response header */
	UNRESTRICTED_AUTH = 105, /* Continue to send authentication (user+password) when following locations,
     even when hostname changed. This can potentially send off the name
     and password to whatever host the server decides. */
	FTP_USE_EPRT = 106, /* Specifically switch on or off the FTP engine's use of the EPRT command (
     it also disables the LPRT attempt). By default, those ones will always be
     attempted before the good old traditional PORT command. */
	HTTPAUTH = 107, /* Set this to a bitmask value to enable the particular authentications
     methods you like. Use this in combination with CURLOPT_USERPWD.
     Note that setting multiple bits may cause extra network round-trips. */
	SSL_CTX_FUNCTION = 20108, /* Set the ssl context callback function, currently only for OpenSSL or
     wolfSSL ssl_ctx, or mbedTLS mbedtls_ssl_config in the second argument.
     The function must match the curl_ssl_ctx_callback prototype. */
	SSL_CTX_DATA = 10109, /* Set the userdata for the ssl context callback function's third
     argument */
	FTP_CREATE_MISSING_DIRS = 110, /* FTP Option that causes missing dirs to be created on the remote server.
     In 7.19.4 we introduced the convenience enums for this option using the
     CURLFTP_CREATE_DIR prefix.
  */
	PROXYAUTH = 111, /* Set this to a bitmask value to enable the particular authentications
     methods you like. Use this in combination with CURLOPT_PROXYUSERPWD.
     Note that setting multiple bits may cause extra network round-trips. */
	SERVER_RESPONSE_TIMEOUT = 112, /* Option that changes the timeout, in seconds, associated with getting a
     response. This is different from transfer timeout time and essentially
     places a demand on the server to acknowledge commands in a timely
     manner. For FTP, SMTP, IMAP and POP3. */
	IPRESOLVE = 113, /* Set this option to one of the CURL_IPRESOLVE_* defines (see below) to
     tell libcurl to use those IP versions only. This only has effect on
     systems with support for more than one, i.e IPv4 _and_ IPv6. */
	MAXFILESIZE = 114, /* Set this option to limit the size of a file that will be downloaded from
     an HTTP or FTP server.

     Note there is also _LARGE version which adds large file support for
     platforms which have larger off_t sizes. See MAXFILESIZE_LARGE below. */
	INFILESIZE_LARGE = 30115, /* See the comment for INFILESIZE above, but in short, specifies
   * the size of the file being uploaded.  -1 means unknown.
   */
	RESUME_FROM_LARGE = 30116, /* Sets the continuation offset. There is also a CURLOPTTYPE_LONG version
   * of this; look above for RESUME_FROM.
   */
	MAXFILESIZE_LARGE = 30117, /* Sets the maximum size of data that will be downloaded from
   * an HTTP or FTP server. See MAXFILESIZE above for the LONG version.
   */
	NETRC_FILE = 10118, /* Set this option to the filename of your .netrc file you want libcurl
     to parse (using the CURLOPT_NETRC option). If not set, libcurl will do
     a poor attempt to find the user's home directory and check for a .netrc
     file in there. */
	USE_SSL = 119, /* Enable SSL/TLS for FTP, pick one of:
     CURLUSESSL_TRY     - try using SSL, proceed anyway otherwise
     CURLUSESSL_CONTROL - SSL for the control connection or fail
     CURLUSESSL_ALL     - SSL for all communication or fail
  */
	POSTFIELDSIZE_LARGE = 30120, /* The _LARGE version of the standard POSTFIELDSIZE option */
	TCP_NODELAY = 121, /* Enable/disable the TCP Nagle algorithm */
	FTPSSLAUTH = 129, /* When FTP over SSL/TLS is selected (with CURLOPT_USE_SSL), this option
     can be used to change libcurl's default action which is to first try
     "AUTH SSL" and then "AUTH TLS" in this order, and proceed when a OK
     response has been received.

     Available parameters are:
     CURLFTPAUTH_DEFAULT - let libcurl decide
     CURLFTPAUTH_SSL     - try "AUTH SSL" first, then TLS
     CURLFTPAUTH_TLS     - try "AUTH TLS" first, then SSL
  */
	IOCTLFUNCTION = 20130, /* When FTP over SSL/TLS is selected (with CURLOPT_USE_SSL), this option
     can be used to change libcurl's default action which is to first try
     "AUTH SSL" and then "AUTH TLS" in this order, and proceed when a OK
     response has been received.

     Available parameters are:
     CURLFTPAUTH_DEFAULT - let libcurl decide
     CURLFTPAUTH_SSL     - try "AUTH SSL" first, then TLS
     CURLFTPAUTH_TLS     - try "AUTH TLS" first, then SSL
  */
	IOCTLDATA = 10131, /* When FTP over SSL/TLS is selected (with CURLOPT_USE_SSL), this option
     can be used to change libcurl's default action which is to first try
     "AUTH SSL" and then "AUTH TLS" in this order, and proceed when a OK
     response has been received.

     Available parameters are:
     CURLFTPAUTH_DEFAULT - let libcurl decide
     CURLFTPAUTH_SSL     - try "AUTH SSL" first, then TLS
     CURLFTPAUTH_TLS     - try "AUTH TLS" first, then SSL
  */
	FTP_ACCOUNT = 10134, /* null-terminated string for pass on to the FTP server when asked for
     "account" info */
	COOKIELIST = 10135, /* feed cookie into cookie engine */
	IGNORE_CONTENT_LENGTH = 136, /* ignore Content-Length */
	FTP_SKIP_PASV_IP = 137, /* Set to non-zero to skip the IP address received in a 227 PASV FTP server
     response. Typically used for FTP-SSL purposes but is not restricted to
     that. libcurl will then instead use the same IP address it used for the
     control connection. */
	FTP_FILEMETHOD = 138, /* Select "file method" to use when doing FTP, see the curl_ftpmethod
     above. */
	LOCALPORT = 139, /* Local port number to bind the socket to */
	LOCALPORTRANGE = 140, /* Number of ports to try, including the first one set with LOCALPORT.
     Thus, setting it to 1 will make no additional attempts but the first.
  */
	CONNECT_ONLY = 141, /* no transfer, set up connection and let application use the socket by
     extracting it with CURLINFO_LASTSOCKET */
	CONV_FROM_NETWORK_FUNCTION = 20142, /* Function that will be called to convert from the
     network encoding (instead of using the iconv calls in libcurl) */
	CONV_TO_NETWORK_FUNCTION = 20143, /* Function that will be called to convert to the
     network encoding (instead of using the iconv calls in libcurl) */
	CONV_FROM_UTF8_FUNCTION = 20144, /* Function that will be called to convert from UTF8
     (instead of using the iconv calls in libcurl)
     Note that this is used only for SSL certificate processing */
	MAX_SEND_SPEED_LARGE = 30145, /* if the connection proceeds too quickly then need to slow it down */
	/* limit-rate: maximum number of bytes per second to send or receive */
	MAX_RECV_SPEED_LARGE = 30146, /* if the connection proceeds too quickly then need to slow it down */
	/* limit-rate: maximum number of bytes per second to send or receive */
	FTP_ALTERNATIVE_TO_USER = 10147, /* Pointer to command string to send if USER/PASS fails. */
	SOCKOPTFUNCTION = 20148, /* callback function for setting socket options */
	SOCKOPTDATA = 10149, /* callback function for setting socket options */
	SSL_SESSIONID_CACHE = 150, /* set to 0 to disable session ID reuse for this transfer, default is
     enabled (== 1) */
	SSH_AUTH_TYPES = 151, /* allowed SSH authentication methods */
	SSH_PUBLIC_KEYFILE = 10152, /* Used by scp/sftp to do public/private key authentication */
	SSH_PRIVATE_KEYFILE = 10153, /* Used by scp/sftp to do public/private key authentication */
	FTP_SSL_CCC = 154, /* Send CCC (Clear Command Channel) after authentication */
	TIMEOUT_MS = 155, /* Same as TIMEOUT and CONNECTTIMEOUT, but with ms resolution */
	CONNECTTIMEOUT_MS = 156, /* Same as TIMEOUT and CONNECTTIMEOUT, but with ms resolution */
	HTTP_TRANSFER_DECODING = 157, /* set to zero to disable the libcurl's decoding and thus pass the raw body
     data to the application even when it is encoded/compressed */
	HTTP_CONTENT_DECODING = 158, /* set to zero to disable the libcurl's decoding and thus pass the raw body
     data to the application even when it is encoded/compressed */
	NEW_FILE_PERMS = 159, /* Permission used when creating new files and directories on the remote
     server for protocols that support it, SFTP/SCP/FILE */
	NEW_DIRECTORY_PERMS = 160, /* Permission used when creating new files and directories on the remote
     server for protocols that support it, SFTP/SCP/FILE */
	POSTREDIR = 161, /* Set the behavior of POST when redirecting. Values must be set to one
     of CURL_REDIR* defines below. This used to be called CURLOPT_POST301 */
	SSH_HOST_PUBLIC_KEY_MD5 = 10162, /* used by scp/sftp to verify the host's public key */
	OPENSOCKETFUNCTION = 20163, /* Callback function for opening socket (instead of socket(2)). Optionally,
     callback is able change the address or refuse to connect returning
     CURL_SOCKET_BAD. The callback should have type
     curl_opensocket_callback */
	OPENSOCKETDATA = 10164, /* Callback function for opening socket (instead of socket(2)). Optionally,
     callback is able change the address or refuse to connect returning
     CURL_SOCKET_BAD. The callback should have type
     curl_opensocket_callback */
	COPYPOSTFIELDS = 10165, /* POST volatile input fields. */
	PROXY_TRANSFER_MODE = 166, /* set transfer mode (;type=<a|i>) when doing FTP via an HTTP proxy */
	SEEKFUNCTION = 20167, /* Callback function for seeking in the input stream */
	SEEKDATA = 10168, /* Callback function for seeking in the input stream */
	CRLFILE = 10169, /* CRL file */
	ISSUERCERT = 10170, /* Issuer certificate */
	ADDRESS_SCOPE = 171, /* (IPv6) Address scope */
	CERTINFO = 172, /* Collect certificate chain info and allow it to get retrievable with
     CURLINFO_CERTINFO after the transfer is complete. */
	USERNAME = 10173, /* "name" and "pwd" to use when fetching. */
	PASSWORD = 10174, /* "name" and "pwd" to use when fetching. */
	PROXYUSERNAME = 10175, /* "name" and "pwd" to use with Proxy when fetching. */
	PROXYPASSWORD = 10176, /* "name" and "pwd" to use with Proxy when fetching. */
	NOPROXY = 10177, /* Comma separated list of hostnames defining no-proxy zones. These should
     match both hostnames directly, and hostnames within a domain. For
     example, local.com will match local.com and www.local.com, but NOT
     notlocal.com or www.notlocal.com. For compatibility with other
     implementations of this, .local.com will be considered to be the same as
     local.com. A single * is the only valid wildcard, and effectively
     disables the use of proxy. */
	TFTP_BLKSIZE = 178, /* block size for TFTP transfers */
	SOCKS5_GSSAPI_SERVICE = 10179, /* Socks Service */
	/* DEPRECATED, do not use! */
	SOCKS5_GSSAPI_NEC = 180, /* Socks Service */
	PROTOCOLS = 181, /* set the bitmask for the protocols that are allowed to be used for the
     transfer, which thus helps the app which takes URLs from users or other
     external inputs and want to restrict what protocol(s) to deal
     with. Defaults to CURLPROTO_ALL. */
	REDIR_PROTOCOLS = 182, /* set the bitmask for the protocols that libcurl is allowed to follow to,
     as a subset of the CURLOPT_PROTOCOLS ones. That means the protocol needs
     to be set in both bitmasks to be allowed to get redirected to. */
	SSH_KNOWNHOSTS = 10183, /* set the SSH knownhost filename to use */
	SSH_KEYFUNCTION = 20184, /* set the SSH host key callback, must point to a curl_sshkeycallback
     function */
	SSH_KEYDATA = 10185, /* set the SSH host key callback custom pointer */
	MAIL_FROM = 10186, /* set the SMTP mail originator */
	MAIL_RCPT = 10187, /* set the list of SMTP mail receiver(s) */
	FTP_USE_PRET = 188, /* FTP: send PRET before PASV */
	RTSP_REQUEST = 189, /* RTSP request method (OPTIONS, SETUP, PLAY, etc...) */
	RTSP_SESSION_ID = 10190, /* The RTSP session identifier */
	RTSP_STREAM_URI = 10191, /* The RTSP stream URI */
	RTSP_TRANSPORT = 10192, /* The Transport: header to use in RTSP requests */
	RTSP_CLIENT_CSEQ = 193, /* Manually initialize the client RTSP CSeq for this handle */
	RTSP_SERVER_CSEQ = 194, /* Manually initialize the server RTSP CSeq for this handle */
	INTERLEAVEDATA = 10195, /* The stream to pass to INTERLEAVEFUNCTION. */
	INTERLEAVEFUNCTION = 20196, /* Let the application define a custom write method for RTP data */
	WILDCARDMATCH = 197, /* Turn on wildcard matching */
	CHUNK_BGN_FUNCTION = 20198, /* Directory matching callback called before downloading of an
     individual file (chunk) started */
	CHUNK_END_FUNCTION = 20199, /* Directory matching callback called after the file (chunk)
     was downloaded, or skipped */
	FNMATCH_FUNCTION = 20200, /* Change match (fnmatch-like) callback for wildcard matching */
	CHUNK_DATA = 10201, /* Let the application define custom chunk data pointer */
	FNMATCH_DATA = 10202, /* FNMATCH_FUNCTION user pointer */
	RESOLVE = 10203, /* send linked-list of name:port:address sets */
	TLSAUTH_USERNAME = 10204, /* Set a username for authenticated TLS */
	TLSAUTH_PASSWORD = 10205, /* Set a password for authenticated TLS */
	TLSAUTH_TYPE = 10206, /* Set authentication type for authenticated TLS */
	TRANSFER_ENCODING = 207, /* Set to 1 to enable the "TE:" header in HTTP requests to ask for
     compressed transfer-encoded responses. Set to 0 to disable the use of TE:
     in outgoing requests. The current default is 0, but it might change in a
     future libcurl release.

     libcurl will ask for the compressed methods it knows of, and if that
     is not any, it will not ask for transfer-encoding at all even if this
     option is set to 1.

  */
	CLOSESOCKETFUNCTION = 20208, /* Callback function for closing socket (instead of close(2)). The callback
     should have type curl_closesocket_callback */
	CLOSESOCKETDATA = 10209, /* Callback function for closing socket (instead of close(2)). The callback
     should have type curl_closesocket_callback */
	GSSAPI_DELEGATION = 210, /* allow GSSAPI credential delegation */
	DNS_SERVERS = 10211, /* Set the name servers to use for DNS resolution.
   * Only supported by the c-ares DNS backend */
	ACCEPTTIMEOUT_MS = 212, /* Time-out accept operations (currently for FTP only) after this amount
     of milliseconds. */
	TCP_KEEPALIVE = 213, /* Set TCP keepalive */
	TCP_KEEPIDLE = 214, /* non-universal keepalive knobs (Linux, AIX, HP-UX, more) */
	TCP_KEEPINTVL = 215, /* non-universal keepalive knobs (Linux, AIX, HP-UX, more) */
	SSL_OPTIONS = 216, /* Enable/disable specific SSL features with a bitmask, see CURLSSLOPT_* */
	MAIL_AUTH = 10217, /* Set the SMTP auth originator */
	SASL_IR = 218, /* Enable/disable SASL initial response */
	XFERINFOFUNCTION = 20219, /* Function that will be called instead of the internal progress display
   * function. This function should be defined as the curl_xferinfo_callback
   * prototype defines. (Deprecates CURLOPT_PROGRESSFUNCTION) */
	XOAUTH2_BEARER = 10220, /* The XOAUTH2 bearer token */
	DNS_INTERFACE = 10221, /* Set the interface string to use as outgoing network
   * interface for DNS requests.
   * Only supported by the c-ares DNS backend */
	DNS_LOCAL_IP4 = 10222, /* Set the local IPv4 address to use for outgoing DNS requests.
   * Only supported by the c-ares DNS backend */
	DNS_LOCAL_IP6 = 10223, /* Set the local IPv6 address to use for outgoing DNS requests.
   * Only supported by the c-ares DNS backend */
	LOGIN_OPTIONS = 10224, /* Set authentication options directly */
	SSL_ENABLE_NPN = 225, /* Enable/disable TLS NPN extension (http2 over ssl might fail without) */
	SSL_ENABLE_ALPN = 226, /* Enable/disable TLS ALPN extension (http2 over ssl might fail without) */
	EXPECT_100_TIMEOUT_MS = 227, /* Time to wait for a response to an HTTP request containing an
   * Expect: 100-continue header before sending the data anyway. */
	PROXYHEADER = 10228, /* This points to a linked list of headers used for proxy requests only,
     struct curl_slist kind */
	HEADEROPT = 229, /* Pass in a bitmask of "header options" */
	PINNEDPUBLICKEY = 10230, /* The public key in DER form used to validate the peer public key
     this option is used only if SSL_VERIFYPEER is true */
	UNIX_SOCKET_PATH = 10231, /* Path to Unix domain socket */
	SSL_VERIFYSTATUS = 232, /* Set if we should verify the certificate status. */
	SSL_FALSESTART = 233, /* Set if we should enable TLS false start. */
	PATH_AS_IS = 234, /* Do not squash dot-dot sequences */
	PROXY_SERVICE_NAME = 10235, /* Proxy Service Name */
	SERVICE_NAME = 10236, /* Service Name */
	PIPEWAIT = 237, /* Wait/do not wait for pipe/mutex to clarify */
	DEFAULT_PROTOCOL = 10238, /* Set the protocol used when curl is given a URL without a protocol */
	STREAM_WEIGHT = 239, /* Set stream weight, 1 - 256 (default is 16) */
	STREAM_DEPENDS = 10240, /* Set stream dependency on another curl handle */
	STREAM_DEPENDS_E = 10241, /* Set E-xclusive stream dependency on another curl handle */
	TFTP_NO_OPTIONS = 242, /* Do not send any tftp option requests to the server */
	CONNECT_TO = 10243, /* Linked-list of host:port:connect-to-host:connect-to-port,
     overrides the URL's host:port (only for the network layer) */
	TCP_FASTOPEN = 244, /* Set TCP Fast Open */
	KEEP_SENDING_ON_ERROR = 245, /* Continue to send data if the server responds early with an
   * HTTP status code >= 300 */
	PROXY_CAINFO = 10246, /* The CApath or CAfile used to validate the proxy certificate
     this option is used only if PROXY_SSL_VERIFYPEER is true */
	PROXY_CAPATH = 10247, /* The CApath directory used to validate the proxy certificate
     this option is used only if PROXY_SSL_VERIFYPEER is true */
	PROXY_SSL_VERIFYPEER = 248, /* Set if we should verify the proxy in ssl handshake,
     set 1 to verify. */
	PROXY_SSL_VERIFYHOST = 249, /* Set if we should verify the Common name from the proxy certificate in ssl
   * handshake, set 1 to check existence, 2 to ensure that it matches
   * the provided hostname. */
	PROXY_SSLVERSION = 250, /* What version to specifically try to use for proxy.
     See CURL_SSLVERSION defines below. */
	PROXY_TLSAUTH_USERNAME = 10251, /* Set a username for authenticated TLS for proxy */
	PROXY_TLSAUTH_PASSWORD = 10252, /* Set a password for authenticated TLS for proxy */
	PROXY_TLSAUTH_TYPE = 10253, /* Set authentication type for authenticated TLS for proxy */
	PROXY_SSLCERT = 10254, /* name of the file keeping your private SSL-certificate for proxy */
	PROXY_SSLCERTTYPE = 10255, /* type of the file keeping your SSL-certificate ("DER", "PEM", "ENG") for
     proxy */
	PROXY_SSLKEY = 10256, /* name of the file keeping your private SSL-key for proxy */
	PROXY_SSLKEYTYPE = 10257, /* type of the file keeping your private SSL-key ("DER", "PEM", "ENG") for
     proxy */
	PROXY_KEYPASSWD = 10258, /* password for the SSL private key for proxy */
	PROXY_SSL_CIPHER_LIST = 10259, /* Specify which TLS 1.2 (1.1, 1.0) ciphers to use for proxy */
	PROXY_CRLFILE = 10260, /* CRL file for proxy */
	PROXY_SSL_OPTIONS = 261, /* Enable/disable specific SSL features with a bitmask for proxy, see
     CURLSSLOPT_* */
	PRE_PROXY = 10262, /* Name of pre proxy to use. */
	PROXY_PINNEDPUBLICKEY = 10263, /* The public key in DER form used to validate the proxy public key
     this option is used only if PROXY_SSL_VERIFYPEER is true */
	ABSTRACT_UNIX_SOCKET = 10264, /* Path to an abstract Unix domain socket */
	SUPPRESS_CONNECT_HEADERS = 265, /* Suppress proxy CONNECT response headers from user callbacks */
	REQUEST_TARGET = 10266, /* The request target, instead of extracted from the URL */
	SOCKS5_AUTH = 267, /* bitmask of allowed auth methods for connections to SOCKS5 proxies */
	SSH_COMPRESSION = 268, /* Enable/disable SSH compression */
	MIMEPOST = 10269, /* Post MIME data. */
	TIMEVALUE_LARGE = 30270, /* Time to use with the CURLOPT_TIMECONDITION. Specified in number of
     seconds since 1 Jan 1970. */
	HAPPY_EYEBALLS_TIMEOUT_MS = 271, /* Head start in milliseconds to give happy eyeballs. */
	RESOLVER_START_FUNCTION = 20272, /* Function that will be called before a resolver request is made */
	RESOLVER_START_DATA = 10273, /* User data to pass to the resolver start callback. */
	HAPROXYPROTOCOL = 274, /* send HAProxy PROXY protocol header? */
	DNS_SHUFFLE_ADDRESSES = 275, /* shuffle addresses before use when DNS returns multiple */
	TLS13_CIPHERS = 10276, /* Specify which TLS 1.3 ciphers suites to use */
	PROXY_TLS13_CIPHERS = 10277, /* Specify which TLS 1.3 ciphers suites to use */
	DISALLOW_USERNAME_IN_URL = 278, /* Disallow specifying username/login in URL. */
	DOH_URL = 10279, /* DNS-over-HTTPS URL */
	UPLOAD_BUFFERSIZE = 280, /* Preferred buffer size to use for uploads */
	UPKEEP_INTERVAL_MS = 281, /* Time in ms between connection upkeep calls for long-lived connections. */
	CURLU = 10282, /* Specify URL using CURL URL API. */
	TRAILERFUNCTION = 20283, /* add trailing data just after no more data is available */
	TRAILERDATA = 10284, /* pointer to be passed to HTTP_TRAILER_FUNCTION */
	HTTP09_ALLOWED = 285, /* set this to 1L to allow HTTP/0.9 responses or 0L to disallow */
	ALTSVC_CTRL = 286, /* alt-svc control bitmask */
	ALTSVC = 10287, /* alt-svc cache filename to possibly read from/write to */
	MAXAGE_CONN = 288, /* maximum age (idle time) of a connection to consider it for reuse
   * (in seconds) */
	SASL_AUTHZID = 10289, /* SASL authorization identity */
	MAIL_RCPT_ALLOWFAILS = 290, /* allow RCPT TO command to fail for some recipients */
	SSLCERT_BLOB = 40291, /* the private SSL-certificate as a "blob" */
	SSLKEY_BLOB = 40292, /* the private SSL-certificate as a "blob" */
	PROXY_SSLCERT_BLOB = 40293, /* the private SSL-certificate as a "blob" */
	PROXY_SSLKEY_BLOB = 40294, /* the private SSL-certificate as a "blob" */
	ISSUERCERT_BLOB = 40295, /* the private SSL-certificate as a "blob" */
	PROXY_ISSUERCERT = 10296, /* Issuer certificate for proxy */
	PROXY_ISSUERCERT_BLOB = 40297, /* Issuer certificate for proxy */
	SSL_EC_CURVES = 10298, /* the EC curves requested by the TLS client (RFC 8422, 5.1);
   * OpenSSL support via 'set_groups'/'set_curves':
   * https://docs.openssl.org/master/man3/SSL_CTX_set1_curves/
   */
	HSTS_CTRL = 299, /* HSTS bitmask */
	HSTS = 10300, /* HSTS filename */
	HSTSREADFUNCTION = 20301, /* HSTS read callback */
	HSTSREADDATA = 10302, /* HSTS read callback */
	HSTSWRITEFUNCTION = 20303, /* HSTS write callback */
	HSTSWRITEDATA = 10304, /* HSTS write callback */
	AWS_SIGV4 = 10305, /* Parameters for V4 signature */
	DOH_SSL_VERIFYPEER = 306, /* Same as CURLOPT_SSL_VERIFYPEER but for DoH (DNS-over-HTTPS) servers. */
	DOH_SSL_VERIFYHOST = 307, /* Same as CURLOPT_SSL_VERIFYHOST but for DoH (DNS-over-HTTPS) servers. */
	DOH_SSL_VERIFYSTATUS = 308, /* Same as CURLOPT_SSL_VERIFYSTATUS but for DoH (DNS-over-HTTPS) servers. */
	CAINFO_BLOB = 40309, /* The CA certificates as "blob" used to validate the peer certificate
     this option is used only if SSL_VERIFYPEER is true */
	PROXY_CAINFO_BLOB = 40310, /* The CA certificates as "blob" used to validate the proxy certificate
     this option is used only if PROXY_SSL_VERIFYPEER is true */
	SSH_HOST_PUBLIC_KEY_SHA256 = 10311, /* used by scp/sftp to verify the host's public key */
	PREREQFUNCTION = 20312, /* Function that will be called immediately before the initial request
     is made on a connection (after any protocol negotiation step).  */
	PREREQDATA = 10313, /* Data passed to the CURLOPT_PREREQFUNCTION callback */
	MAXLIFETIME_CONN = 314, /* maximum age (since creation) of a connection to consider it for reuse
   * (in seconds) */
	MIME_OPTIONS = 315, /* Set MIME option flags. */
	SSH_HOSTKEYFUNCTION = 20316, /* set the SSH host key callback, must point to a curl_sshkeycallback
     function */
	SSH_HOSTKEYDATA = 10317, /* set the SSH host key callback custom pointer */
	PROTOCOLS_STR = 10318, /* specify which protocols that are allowed to be used for the transfer,
     which thus helps the app which takes URLs from users or other external
     inputs and want to restrict what protocol(s) to deal with. Defaults to
     all built-in protocols. */
	REDIR_PROTOCOLS_STR = 10319, /* specify which protocols that libcurl is allowed to follow directs to */
	WS_OPTIONS = 320, /* WebSockets options */
	CA_CACHE_TIMEOUT = 321, /* CA cache timeout */
	QUICK_EXIT = 322, /* Can leak things, gonna exit() soon */
	HAPROXY_CLIENT_IP = 10323, /* set a specific client IP for HAProxy PROXY protocol header? */
	SERVER_RESPONSE_TIMEOUT_MS = 324, /* millisecond version */
	ECH = 10325, /* set ECH configuration */
	TCP_KEEPCNT = 326, /* maximum number of keepalive probes (Linux, *BSD, macOS, etc.) */
	UPLOAD_FLAGS = 327, /* maximum number of keepalive probes (Linux, *BSD, macOS, etc.) */
	LASTENTRY, /* the last unused */
}

slist :: struct {
	data: cstring,
	next: ^slist,
}

@(default_calling_convention = "c", link_prefix = "curl_")
foreign lib {
	easy_cleanup :: proc(curl: ^CURL) ---
	easy_init :: proc() -> ^CURL ---
	easy_perform :: proc(curl: ^CURL) -> Code ---
	easy_setopt :: proc(curl: ^CURL, option: Option, #c_vararg args: ..any) ---
	easy_strerror :: proc(code: Code) -> cstring ---
	slist_append :: proc(list: ^slist, data: cstring) -> ^slist ---
}
