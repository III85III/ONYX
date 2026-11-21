using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Windows.Forms;

[assembly: AssemblyProduct("ONYX VPN")]
[assembly: AssemblyTitle("ONYX VPN Setup")]
[assembly: AssemblyFileVersion("1.1.27.0")]

internal static class Setup {
    static readonly string Programs = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs");

    internal static string Install(string root) {
        Directory.CreateDirectory(root);
        string staging = Path.Combine(root, ".stage-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(staging);
        try {
            using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
            using (var archive = new ZipArchive(stream)) {
                foreach (var entry in archive.Entries) {
                    string path = Path.GetFullPath(Path.Combine(staging, entry.FullName));
                    if (!path.StartsWith(staging + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Invalid package path.");
                    Directory.CreateDirectory(Path.GetDirectoryName(path));
                    if (entry.Name != "") entry.ExtractToFile(path);
                }
            }
            string version = AssemblyName.GetAssemblyName(Path.Combine(staging,"onyx_vpn.exe")).Version.ToString(3);
            foreach (var name in new[]{"interface/index.html","interface/tailwind.css","interface/icon.png","core/onyx-core.exe","WebView2Loader.dll"})
                if (!File.Exists(Path.Combine(staging,name))) throw new InvalidDataException("Incomplete package.");
            string destination = Path.Combine(root, version);
            if (Directory.Exists(destination)) {
                using (var sha = SHA256.Create()) {
                    foreach (string src in Directory.GetFiles(staging,"*",SearchOption.AllDirectories)) {
                        string target = Path.Combine(destination,src.Substring(staging.Length+1));
                        if (!File.Exists(target) || !SameFile(sha,src,target)) {
                            // Repair beside the in-use build. Switching shortcuts never overwrites a loaded file.
                            destination = Path.Combine(root, version + "-" + Guid.NewGuid().ToString("N"));
                            break;
                        }
                    }
                }
            }
            if (!Directory.Exists(destination)) Directory.Move(staging,destination);
            return Path.Combine(destination,"onyx_vpn.exe");
        } finally { if (Directory.Exists(staging)) Directory.Delete(staging,true); }
    }

    static bool SameFile(HashAlgorithm hash,string a,string b) {
        using(var left=File.OpenRead(a)) using(var right=File.OpenRead(b))
            return left.Length==right.Length && hash.ComputeHash(left).SequenceEqual(hash.ComputeHash(right));
    }

    internal static void Link(string folder,string exe) {
        Directory.CreateDirectory(folder);
        dynamic shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell"));
        foreach (string file in Directory.GetFiles(folder,"*.lnk")) {
            string name = Path.GetFileNameWithoutExtension(file);
            if (!new[]{"85","85 VPN","III85III","III85III VPN","III85III-VPN","ONYX","ONYX VPN"}.Contains(name,StringComparer.OrdinalIgnoreCase)) continue;
            dynamic old = shell.CreateShortcut(file);
            string previous = old.TargetPath;
            if (String.IsNullOrEmpty(previous)) continue;
            bool ours = new[]{"ONYX","ONYX VPN","III85III VPN"}.Any(dir=>previous.StartsWith(Path.Combine(Programs,dir)+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))
                && new[]{"85.exe","III85III VPN.exe","ONYX VPN.exe","onyx_vpn.exe"}.Contains(Path.GetFileName(previous),StringComparer.OrdinalIgnoreCase);
            if(ours) SaveLink(old,exe);
        }
        SaveLink(shell.CreateShortcut(Path.Combine(folder,"ONYX VPN.lnk")),exe);
    }
    static void SaveLink(dynamic link,string exe) {
        link.TargetPath=exe; link.Arguments=""; link.WorkingDirectory=Path.GetDirectoryName(exe);
        link.Description="ONYX VPN"; link.IconLocation=exe+",0"; link.Save();
    }

    [STAThread]
    static int Main() {
        try {
            string exe=Install(Path.Combine(Programs,"ONYX","Versions"));
            Link(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),exe);
            Link(Environment.GetFolderPath(Environment.SpecialFolder.Programs),exe);
            MessageBox.Show("ONYX VPN is installed. When you are ready, exit the previous app and open ONYX VPN from your desktop.","ONYX VPN",MessageBoxButtons.OK,MessageBoxIcon.Information);
            return 0;
        } catch(Exception error) { MessageBox.Show(error.Message,"ONYX VPN setup",MessageBoxButtons.OK,MessageBoxIcon.Error); return 1; }
    }
}
