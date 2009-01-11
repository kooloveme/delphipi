{**
 DelphiPI (Delphi Package Installer)
 Author  : ibrahim dursun (t-hex) thex [at] thexpot ((dot)) net
 License : GNU General Public License 2.0
**}
unit PackageCompiler;

interface
uses JclBorlandTools, PackageInfo, PackageList, SysUtils, Classes, CompilationData, ProgressMonitor;

type
   
   TPackageCompiler = class
   private
     fCompilationData: TCompilationData;
     fCancel: boolean;
     fSourceFilePaths: TStringList;
     fExtraOptions: String;

     function ConvertToShortPaths(const paths : TStringList): string;
    function GetInstallation: TJclBorRADToolInstallation;
    function GetPackageList: TPackageList;
   protected
     procedure PrepareExtraOptions; virtual;
     procedure ResolveHelpFiles(const compilationData: TCompilationData);
     procedure AddSourcePathsToIDE(const sourceFilePaths: TStrings; const installation: TJclBorRADToolInstallation);
     procedure ResolveSourcePaths; virtual;

     property Installation: TJclBorRADToolInstallation read GetInstallation;
     property PackageList: TPackageList read GetPackageList;
   public
     constructor Create(const compilationData: TCompilationData); virtual;
     destructor Destroy; override;
     
     procedure Compile; virtual;
     function CompilePackage(const packageInfo : TPackageInfo): Boolean; virtual;
     function InstallPackage(const packageInfo : TPackageInfo): Boolean; virtual;
  
     //Properties
     property Cancel: boolean read fCancel write fCancel;
     property SourceFilePaths: TStringList read fSourceFilePaths write fSourceFilePaths;
     property ExtraOptions: string read fExtraOptions;
   end;

implementation

uses JclFileUtils, JclStrings;
{ TPackageCompiler }

constructor TPackageCompiler.Create(const compilationData: TCompilationData);
begin
  fCompilationData := compilationData;
  fSourceFilePaths := TStringList.Create;
end;

destructor TPackageCompiler.Destroy;
begin
  fSourceFilePaths.Free;
  
  inherited;
end;

function TPackageCompiler.GetInstallation: TJclBorRADToolInstallation;
begin
  Result := fCompilationData.Installation;
end;

function TPackageCompiler.GetPackageList: TPackageList;
begin
  Result := fCompilationData.PackageList;
end;

procedure TPackageCompiler.Compile;
var
  i: integer;
  info: TPackageInfo;
  compilationSuccessful: boolean;
begin
  PrepareExtraOptions;
    
  if SourceFilePaths.Count = 0 then
    ResolveSourcePaths;
      
  AddSourcePathsToIDE(SourceFilePaths, fCompilationData.Installation);
      
  if fCompilationData.HelpFiles.Count = 0 then
    ResolveHelpFiles(fCompilationData);

  PackageList.SortList;
  for i := 0 to PackageList.Count - 1 do 
  begin
    info := PackageList[i];
    compilationSuccessful := CompilePackage(info);

    if compilationSuccessful and (not info.RunOnly) then
      InstallPackage(info);

    if fCancel then
      break;
  end;
end;

function TPackageCompiler.CompilePackage(
  const packageInfo: TPackageInfo): Boolean;
begin
  Result := Installation.DCC32.MakePackage(
                packageInfo.filename,
                fCompilationData.BPLOutputFolder,
                fCompilationData.DCPOutputFolder,
                fExtraOptions);
end;


procedure TPackageCompiler.PrepareExtraOptions;
var
  shortPaths : string;
  pathList : TStringList;
begin
  pathList := TStringList.Create;
  try
    ExtractStrings([';'],[' '],PWideChar(Installation.LibrarySearchPath),pathList);
    pathList.Add(Installation.BPLOutputPath);
    shortPaths := ConvertToShortPaths(pathList);
  finally
    pathList.Free;
  end;

  fExtraOptions := '-B -Q -CC';
  fExtraOptions := fExtraOptions + ' -I'+shortPaths+'';
  fExtraOptions := fExtraOptions + ' -U'+shortPaths+'';
  fExtraOptions := fExtraOptions + ' -O'+shortPaths+'';
  fExtraOptions := fExtraOptions + ' -R'+shortPaths+'';
end;

function TPackageCompiler.ConvertToShortPaths(const paths : TStringList):string;
var
  path : string;
begin
  Result := '';
  for path in paths do begin
    Result := Result + StrDoubleQuote(PathGetShortName(StrTrimQuotes(path))) + ';';
  end;
end;

function TPackageCompiler.InstallPackage(
  const packageInfo: TPackageInfo): Boolean;
var
  BPLFileName : String;  
begin
  BPLFileName := PathAddSeparator(Installation.BPLOutputPath) + PathExtractFileNameNoExt(packageInfo.FileName) + packageInfo.Suffix + '.bpl';
  Result := Installation.RegisterPackage(BPLFileName, packageInfo.Description);
end;

//TODO: refactor -- finds paths of files have .pas extension and then matches pas files in packages, removes remaining paths 
procedure TPackageCompiler.ResolveSourcePaths;
var
  i,j: integer;
  files, containedFiles: TStringList;
begin
  Assert(assigned(SourceFilePaths));
  
  
  files := TStringList.Create;
  files.Sorted := true;
  files.Duplicates := dupIgnore;

  containedFiles := TStringList.Create;
  containedFiles.Sorted := true;
  containedFiles.Duplicates := dupIgnore;

  SourceFilePaths.Clear;   
  SourceFilePaths.Sorted := true;
  SourceFilePaths.Duplicates := dupIgnore;
     
  for i := 0 to PackageList.Count - 1 do begin
    SourceFilePaths.Add(ExtractFileDir(PackageList[i].FileName));
    for j := 0 to PackageList[i].ContainedFileList.Count - 1 do
      containedFiles.Add(ExtractFileName(PackageList[i].ContainedFileList[j]));
  end;

  AdvBuildFileList(fCompilationData.BaseFolder+'\*.pas',
           faAnyFile,
           files,
           amAny,
           [flFullnames, flRecursive],
           '', nil);
           
  
  for I := 0 to files.count - 1 do begin
    if containedFiles.IndexOf(ExtractFileName(files[i])) > 0 then
      begin
        SourceFilePaths.Add(ExtractFileDir(files[i]));
      end;
  end;
end;

procedure TPackageCompiler.ResolveHelpFiles(const compilationData: TCompilationData);
var
  files: TStringList;
  filename: string;
begin
  assert(assigned(fCompilationData));

  files := TStringList.Create;
  try
    AdvBuildFileList(compilationData.BaseFolder +'\*.hlp',
           faAnyFile,
           files,
           amAny,
           [flFullnames, flRecursive],
           '', nil);
     for filename in files do
       compilationData.HelpFiles.Add(filename);
  finally
    files.Free;
  end;
end;

procedure TPackageCompiler.AddSourcePathsToIDE(const sourceFilePaths: TStrings; const installation: TJclBorRADToolInstallation);
var
  path : string;
begin
  Assert(assigned(sourceFilePaths));
  Assert(assigned(installation));
  for path in sourceFilePaths do
  begin
    installation.AddToLibrarySearchPath(path);
  end;
end;

end.
