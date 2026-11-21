using System;
using System.ServiceProcess;
using System.Threading;

namespace AEBDemo {
  public class ServiceHost : ServiceBase {
    private Thread thread;
    private volatile bool running;
    public ServiceHost() { ServiceName = "AEBTestService"; CanStop = true; }
    protected override void OnStart(string[] args) {
      running = true;
      thread = new Thread(() => { while(running) Thread.Sleep(500); });
      thread.IsBackground = true;
      thread.Start();
    }
    protected override void OnStop() { running = false; if(thread != null) thread.Join(3000); }
    public static void Main() { ServiceBase.Run(new ServiceHost()); }
  }
}
