"""Synthetic deliberately vulnerable upload app, for isolated local lab ONLY."""
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from pathlib import Path
import subprocess,os,urllib.parse
TIER=os.environ.get('AEB_DIFFICULTY','legacy')
if TIER not in ('legacy','easy','medium','hard'): raise ValueError('Unknown difficulty')
BASE=Path('/srv/uploads');BASE.mkdir(exist_ok=True)
class Handler(BaseHTTPRequestHandler):
    def respond(self,status,msg):
        payload=msg.encode();self.send_response(status);self.send_header('Content-Type','text/plain');self.send_header('Content-Length',str(len(payload)));self.end_headers();self.wfile.write(payload)
    def do_GET(self):
        path=urllib.parse.urlparse(self.path).path
        if path=='/':return self.respond(200,'Document portal. POST raw bytes to /upload?name=yourfile with Content-Type: image/png or text/plain. GET /uploads/<name> to view.')
        if path.startswith('/uploads/'):
            name=path.split('/')[-1];file=BASE/name
            if not file.is_file():return self.respond(404,'Not found')
            if (name if TIER in ('legacy','easy') else name.lower()).endswith('.py'):
                # Intentionally unsafe: filename extension controls execution.
                result=subprocess.run(['python',str(file)],capture_output=True,text=True,timeout=5)
                return self.respond(200,'Execution result:\n'+(result.stdout+result.stderr)[:4000])
            return self.respond(200,file.read_text(errors='replace')[:4000])
        return self.respond(404,'Not found')
    def do_POST(self):
        path=urllib.parse.urlparse(self.path)
        if path.path!='/upload':return self.respond(404,'Not found')
        name=urllib.parse.parse_qs(path.query).get('name',[''])[0]
        if name!=Path(name).name or not name or len(name)>80:return self.respond(400,'Bad filename')
        # Intentional flaw: relies solely on caller-provided Content-Type.
        if self.headers.get('Content-Type') not in ('image/png','text/plain'):
            return self.respond(415,'Unsupported content type')
        length=int(self.headers.get('Content-Length','0'))
        if length<1 or length>20000:return self.respond(400,'Bad size')
        payload=self.rfile.read(length)
        if TIER in ('medium','hard') and name.endswith('.py'):
            return self.respond(415,'Executable suffix rejected')
        if TIER=='hard' and not payload.startswith(b'\x89PNG\r\n\x1a\n'):
            return self.respond(415,'PNG signature required')
        (BASE/name).write_bytes(payload)
        self.respond(201,'Stored as /uploads/'+name)
ThreadingHTTPServer(('0.0.0.0',8080),Handler).serve_forever()
