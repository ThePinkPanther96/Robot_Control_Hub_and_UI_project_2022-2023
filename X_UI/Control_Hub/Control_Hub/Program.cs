//// See https://aka.ms/new-console-template for more information
//using System.Diagnostics;
//string powershellPath = @"C:\Program Files\PowerShell\7\pwsh.exe";
//// Replace "C:\Path\to\Main.ps1" with the full path to your main PowerShell script
//string scriptPath = @"Main.ps1";
//var info = new ProcessStartInfo();
//info.FileName = powershellPath;
//info.UseShellExecute = true;
//info.Arguments = $"-ExecutionPolicy Bypass -File \"{scriptPath}\"";
//info.CreateNoWindow = true;
////info.RedirectStandardInput = true;
////info.RedirectStandardOutput = true;
////info.RedirectStandardError = true;
////info.WindowStyle = ProcessWindowStyle.Hidden;
//Process.Start(info);

using System;
using System.Diagnostics;

namespace PowerShellLauncher
{
    class Program
    {
        static void Main()
        {
            // Replace "powershell.exe" with the path to your PowerShell executable
            string powershellPath = @"C:\Program Files\PowerShell\7\pwsh.exe";
            // Replace "C:\Path\to\Main.ps1" with the full path to your main PowerShell script
            string scriptPath = @"Main.ps1";

            ProcessStartInfo psi = new ProcessStartInfo(powershellPath)
            {
                Arguments = $"-ExecutionPolicy Bypass -File \"{scriptPath}\"",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden,
                FileName = powershellPath,
                RedirectStandardError = true,
                RedirectStandardInput = true

            };

            Process process = new Process
            {
                StartInfo = psi

            };

            // Register AppDomain.ProcessExit event
            AppDomain.CurrentDomain.ProcessExit += (sender, e) =>
            {
                // Terminate the PowerShell process explicitly
                if (!process.HasExited)
                {
                    process.Kill();
                    process.WaitForExit(); // Wait for the process to be killed
                }
            };

            process.Start();

            string output = process.StandardOutput.ReadToEnd();
            process.WaitForExit();

            Console.WriteLine(output);
        }
    }
}
