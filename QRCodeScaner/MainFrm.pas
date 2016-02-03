unit MainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, FMX.Media, FMX.Platform, FMX.MultiView, FMX.ListView.Types,
  FMX.ListView, FMX.Layouts, System.Actions, FMX.ActnList, FMX.TabControl,
  FMX.ListBox, Threading, BarcodeFormat, ReadResult,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, ScanManager;

type
  TMainForm = class(TForm)
    btnStartCamera: TButton;
    btnStopCamera: TButton;
    lblScanStatus: TLabel;
    imgCamera: TImage;
    ToolBarTop: TToolBar;
    btnMenu: TButton;
    Layout: TLayout;
    ToolBarBottom: TToolBar;
    CameraComponent: TCameraComponent;
    Memo: TMemo;
    procedure btnStartCameraClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnStopCameraClick(Sender: TObject);

    procedure FormDestroy(Sender: TObject);
    procedure CameraComponentSampleBufferReady(Sender: TObject;
      const ATime: TMediaTime);
  private
    { Private declarations }

    FScanManager: TScanManager;
    FScanInProgress: Boolean;
    frameTake: Integer;
    procedure GetImage();
    function AppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;

  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
var
  AppEventSvc: IFMXApplicationEventService;
begin

  lblScanStatus.Text := '';
  frameTake := 0;

  { by default, we start with Front Camera and Flash Off }
  { cbFrontCamera.IsChecked := True;
    CameraComponent1.Kind := FMX.Media.TCameraKind.ckFrontCamera;

    cbFlashOff.IsChecked := True;
    if CameraComponent1.HasFlash then
    CameraComponent1.FlashMode := FMX.Media.TFlashMode.fmFlashOff;
  }

  { Add platform service to see camera state. }
  if TPlatformServices.Current.SupportsPlatformService
    (IFMXApplicationEventService, IInterface(AppEventSvc)) then
    AppEventSvc.SetApplicationEventHandler(AppEvent);

  CameraComponent.Quality := FMX.Media.TVideoCaptureQuality.MediumQuality;
  lblScanStatus.Text := '';
  FScanManager := TScanManager.Create(TBarcodeFormat.Auto, nil);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FScanManager.DisposeOf;
end;

procedure TMainForm.btnStartCameraClick(Sender: TObject);
begin
  CameraComponent.Active := False;
  CameraComponent.Kind := FMX.Media.TCameraKind.BackCamera;
  CameraComponent.Active := True;

  lblScanStatus.Text := '';
  Memo.Lines.Clear;
end;

procedure TMainForm.btnStopCameraClick(Sender: TObject);
begin
  CameraComponent.Active := False;
end;

procedure TMainForm.CameraComponentSampleBufferReady(Sender: TObject;
  const ATime: TMediaTime);
begin
  TThread.Synchronize(TThread.CurrentThread, GetImage);
end;

procedure TMainForm.GetImage;
var
  ScanBitmap: TBitmap;
  ReadResult: TReadResult;
begin
  try
    CameraComponent.SampleBufferToBitmap(imgCamera.Bitmap, True);
    if (FScanInProgress) then
      Exit;

    {
      inc(frameTake);
      if (frameTake mod 4 <> 0) then
      begin
      Exit;
      end;
    }

    ScanBitmap := TBitmap.Create();
    ScanBitmap.Assign(imgCamera.Bitmap);

    TTask.Run(
      procedure
      begin
        try
          FScanInProgress := True;

          ScanBitmap.Assign(imgCamera.Bitmap);

          ReadResult := FScanManager.Scan(ScanBitmap);
          FScanInProgress := False;
        except
          on E: Exception do
          begin
            FScanInProgress := False;
            TThread.Synchronize(nil,
              procedure
              begin
                // lblScanStatus.Text := E.Message;
                // lblScanResults.Text := '';
              end);
            if Assigned(ScanBitmap) then
              ScanBitmap.DisposeOf;

            Exit;
          end;
        end;

        TThread.Synchronize(nil,
          procedure
          begin
            try
              if (length(lblScanStatus.Text) > 10) then
                lblScanStatus.Text := '*';

              lblScanStatus.Text := lblScanStatus.Text + '*';

              if Assigned(ReadResult) then
                Memo.Lines.Insert(0, ReadResult.Text);

              if Assigned(ScanBitmap) then
                ScanBitmap.DisposeOf;
             except

             end
          end);
      end);
  except

  end;
end;

{ Make sure the camera is released if you're going away. }
function TMainForm.AppEvent(AAppEvent: TApplicationEvent;
AContext: TObject): Boolean;
begin
//  case AAppEvent of
//    TApplicationEvent.WillBecomeInactive:
//      CameraComponent.Active := False;
//    TApplicationEvent.EnteredBackground:
//      CameraComponent.Active := False;
//    TApplicationEvent.WillTerminate:
//      CameraComponent.Active := False;
//  end;
end;

end.
