package main

import (
	"net/http"
	"net/http/cgi"
	"os"
	"path/filepath"
    "log"
    "flag"
    "fmt"
    "strings"
)

type CgiHandler struct {
	http.Handler
	Root       string
	Default    string
    CGIroot    string
    CGIpfx     string
}

func CgiServer(rootdir string, cgidir string) *CgiHandler {
	rPath, _ := filepath.Abs(rootdir)
	cPath, _ := filepath.Abs(cgidir)
	return &CgiHandler{nil, rPath, "index.html", cPath, "cgi"}
}

func (h *CgiHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var isCGI bool
	file := filepath.Base(r.URL.Path)
	path := filepath.Dir(r.URL.Path)
	if len(file) > 0 && os.IsPathSeparator(file[len(file)-1]) {
		file = file[:len(file)-1]
	}
    mstr := fmt.Sprintf("/%s",h.CGIpfx)
    cURL := mstr+"/"
    isCGI,err := filepath.Match(mstr,path)
    if err != nil {
        if ! hQuiet {log.Fatal(err)}
    }

	if isCGI {
	    file = filepath.Join(h.CGIroot, file)
        if ! hQuiet {log.Printf("Launching CGI %s\n",file)}
        if f,e := os.Stat(file); err == nil {
            if f == nil {
                if ! hQuiet {log.Printf("CGI Application Not Found %s",file)}
                http.NotFound(w,r)
                return
            }
            if f.IsDir() {
                if ! hQuiet {log.Printf("Invalid CGI Application %s",file)}
                http.NotFound(w,r)
                return
            }
            var cgih cgi.Handler
            cgih = cgi.Handler{
                Path: file,
                Root: cURL, 
                InheritEnv: strings.Split(hEnv,","),
            }
            cgih.ServeHTTP(w, r)
        } else {
            log.Println(e)
            http.Error(w,"Error Serving CGI",404)
            return
        }
	} else {
        if len(file) > 0 {
	        file = filepath.Join(h.Root, h.Default)
        } else {
	        file = filepath.Join(h.Root, file)
        }
        f, e := os.Stat(file)
		if (f != nil && f.IsDir()) || file == "" {
			tmp := filepath.Join(file, h.Default)
			f, e = os.Stat(tmp)
			if e == nil {
				file = tmp
			}
		}
        if ! hQuiet {log.Printf("Sending %s\n",file)}
		http.ServeFile(w, r, file)
	}
}

var hPort int
var hDefault string
var hRoot string
var hCGIpfx string
var hCGIdir string
var hQuiet bool
var hEnv string

func init() {
    const (
        portDefault = 8080
        portUsage = "Port to serve on"
        webDefault = "index.html"
        webUsage = "Default file name"
        htmlDefault = "./html"
        htmlUsage = "Webserver root path"
        cgiDefault = "cgi"
        cgiUsage = "CGI URL subdirectory path prefix"
        cgiDir = "./cgi"
        cgiDirUsage = "Path to CGI files"
        envUsage = "quoted, comma separated list of environemnt variables to pass to CGI"
        )
    flag.IntVar(&hPort,"port",portDefault,portUsage)
    flag.IntVar(&hPort,"p",portDefault,portUsage+" (shorthand)")
    flag.StringVar(&hDefault,"default",webDefault,webUsage)
    flag.StringVar(&hDefault,"d",webDefault,webUsage+" (shorthand)")
    flag.StringVar(&hRoot,"html",htmlDefault,htmlUsage)
    flag.StringVar(&hRoot,"H",htmlDefault,htmlUsage+" (shorthand)")
    flag.StringVar(&hCGIpfx,"cgi-prefix",cgiDefault,cgiUsage)
    flag.StringVar(&hCGIpfx,"c",cgiDefault,cgiUsage+" (shorthand)")
    flag.StringVar(&hCGIdir,"cgi-dir",cgiDir,cgiDirUsage)
    flag.StringVar(&hCGIdir,"C",cgiDir,cgiDirUsage+" (shorthand)")
    flag.StringVar(&hEnv,"env","",envUsage)
    flag.StringVar(&hEnv,"e","",envUsage+" (shorthand)")
    flag.BoolVar(&hQuiet,"q",false,"Silence Log Messages (except errors)")
    flag.Parse()
}

func cleanPath (path string) string {
    tmp,err := filepath.Abs(path)
    if err != nil {
        log.Fatal(err)
    }
    return(tmp)
}

func main() {
    if ! hQuiet {
        log.Printf("Starting CGI Server on port %d with default filename of %s\n",hPort,hDefault)
    }
    rootdir := cleanPath(hRoot)
    cgidir := cleanPath(hCGIdir)
    if ! hQuiet {
        log.Printf("Base directory is %s\n",rootdir)
        log.Printf("CGI subdirectory is %s\n",cgidir)
    }
	c := CgiServer(rootdir,cgidir)
    c.Default=hDefault
    c.CGIpfx=hCGIpfx
    listenPort:=fmt.Sprintf(":%d",hPort)
	log.Fatal(http.ListenAndServe(listenPort, c))
}
