// Local Album Frame native settings window. MIT.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Web.Script.Serialization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Markup;
public static class AlbumSettings {
 [STAThread] public static int Main(string[] args) {
  try {
   string root=Directory.GetParent(AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar)).FullName;
   string path=Path.Combine(root,"settings.json");
   var json=new JavaScriptSerializer();
   var data=new Dictionary<string,object>{{"MediaRoot",Environment.GetFolderPath(Environment.SpecialFolder.MyPictures)},{"ImageSeconds",30},{"Shuffle",true},{"IncludeVideos",true},{"PlaySound",false},{"ShowClock",true},{"RandomClockCorner",true},{"ShowMediaInfo",true}};
   if(File.Exists(path)){foreach(var item in json.Deserialize<Dictionary<string,object>>(File.ReadAllText(path,Encoding.UTF8)))data[item.Key]=item.Value;}
   Window window;
   using(var stream=File.OpenRead(Path.Combine(root,"Settings.xaml")))window=(Window)XamlReader.Load(stream);
   window.MaxWidth=SystemParameters.WorkArea.Width;window.MaxHeight=SystemParameters.WorkArea.Height;window.Height=Math.Min(714,SystemParameters.WorkArea.Height-12);
   var folder=(TextBox)window.FindName("FolderBox");var seconds=(TextBox)window.FindName("SecondsBox");
   var random=(RadioButton)window.FindName("RandomButton");var sequential=(RadioButton)window.FindName("SequentialButton");
   var videos=(CheckBox)window.FindName("VideosBox");var sound=(CheckBox)window.FindName("SoundBox");var clock=(CheckBox)window.FindName("ClockBox");var corner=(CheckBox)window.FindName("CornerBox");
   var mediaInfo=(CheckBox)window.FindName("MediaInfoBox");
   folder.Text=Convert.ToString(data["MediaRoot"]);seconds.Text=Convert.ToString(data["ImageSeconds"]);
   random.IsChecked=Convert.ToBoolean(data["Shuffle"]);sequential.IsChecked=!random.IsChecked.Value;
   videos.IsChecked=Convert.ToBoolean(data["IncludeVideos"]);sound.IsChecked=Convert.ToBoolean(data["PlaySound"]);clock.IsChecked=Convert.ToBoolean(data["ShowClock"]);corner.IsChecked=Convert.ToBoolean(data["RandomClockCorner"]);
   mediaInfo.IsChecked=Convert.ToBoolean(data["ShowMediaInfo"]);
   ((Button)window.FindName("BrowseButton")).Click+=(s,e)=>{using(var picker=new System.Windows.Forms.FolderBrowserDialog()){picker.Description="选择照片和视频所在的文件夹";picker.SelectedPath=folder.Text;if(picker.ShowDialog()==System.Windows.Forms.DialogResult.OK)folder.Text=picker.SelectedPath;}};
   ((Button)window.FindName("MinusButton")).Click+=(s,e)=>{int n;if(int.TryParse(seconds.Text,out n))seconds.Text=Math.Max(1,n-5).ToString();};
   ((Button)window.FindName("PlusButton")).Click+=(s,e)=>{int n;if(int.TryParse(seconds.Text,out n))seconds.Text=Math.Min(86400,n+5).ToString();};
   foreach(int n in new[]{5,10,15,30,60}){var preset=(Button)window.FindName("Preset"+n);preset.Tag=n;preset.Click+=(s,e)=>{seconds.Text=((Button)s).Tag.ToString();};}
   bool played=false;
   ((Button)window.FindName("CloseButton")).Click+=(s,e)=>window.Close();
   ((Button)window.FindName("PlayButton")).Click+=(s,e)=>{try {
    int n;if(!int.TryParse(seconds.Text,out n)||n<1||n>86400)throw new Exception("请输入1至86400之间的整数秒数。");
    if(!Directory.Exists(folder.Text))throw new Exception("该文件夹暂时无法访问。请先确认 CloudDrive 的挂载状态。");
    data["MediaRoot"]=folder.Text;data["ImageSeconds"]=n;data["Shuffle"]=random.IsChecked==true;data["IncludeVideos"]=videos.IsChecked==true;data["PlaySound"]=sound.IsChecked==true;data["ShowClock"]=clock.IsChecked==true;data["RandomClockCorner"]=corner.IsChecked==true;
    data["ShowMediaInfo"]=mediaInfo.IsChecked==true;
    string temp=path+".tmp";File.WriteAllText(temp,json.Serialize(data),new UTF8Encoding(false));if(File.Exists(path))File.Replace(temp,path,null);else File.Move(temp,path);
    Process.Start(new ProcessStartInfo{FileName=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"),Arguments="-NoProfile -ExecutionPolicy Bypass -File \""+Path.Combine(root,"Launch.ps1")+"\"",UseShellExecute=false,CreateNoWindow=true,WorkingDirectory=root});
    played=true;window.Close();
   }catch(Exception ex){MessageBox.Show(window,ex.Message,"请检查设置",MessageBoxButton.OK,MessageBoxImage.Warning);}};
   window.Topmost=true;window.ContentRendered+=(s,e)=>{window.Activate();window.Topmost=false;};new Application().Run(window);return played?10:0;
  }catch(Exception ex){MessageBox.Show(ex.Message,"设置窗口未能启动",MessageBoxButton.OK,MessageBoxImage.Error);return 1;}
 }
}
