unit ScanManager;

interface

uses SysUtils, FMX.Graphics, generics.collections, RGBLuminanceSource,
  HybridBinarizer, BinaryBitmap,
  MultiFormatReader, ReadResult, BarcodeFormat, DecodeHintType;

type
  TScanManager = class
  private
    FMultiFormatReader: TMultiFormatReader;

    function GetMultiFormatReader(format: TBarcodeFormat;
      additionalHints: TDictionary<TDecodeHintType, TObject>)
      : TMultiFormatReader;
  public
    destructor Destroy; override;
    function Scan(pBitmapForScan: TBitmap): TReadResult;
    constructor Create(format: TBarcodeFormat;
      additionalHints: TDictionary<TDecodeHintType, TObject>);

  end;

implementation

function TScanManager.Scan(pBitmapForScan: TBitmap): TReadResult;
var
  RGBLuminanceSource: TRGBLuminanceSource;
  HybridBinarizer: THybridBinarizer;
  BinaryBitmap: TBinaryBitmap;
begin
  try
    try
      RGBLuminanceSource := TRGBLuminanceSource.RGBLuminanceSource(pBitmapForScan,
        pBitmapForScan.Width, pBitmapForScan.Height);

      HybridBinarizer := THybridBinarizer.Create(RGBLuminanceSource);

      BinaryBitmap := TBinaryBitmap.BinaryBitmap(HybridBinarizer);

      Result := FMultiFormatReader.Decode(BinaryBitmap);

    finally
      if Assigned(BinaryBitmap) then
        BinaryBitmap.DisposeOf;

      if Assigned(HybridBinarizer) then
        HybridBinarizer.DisposeOf;

      if Assigned(RGBLuminanceSource) then
        RGBLuminanceSource.DisposeOf;
    end;
  except

  end;
end;

constructor TScanManager.Create(format: TBarcodeFormat;
  additionalHints: TDictionary<TDecodeHintType, TObject>);
begin
  inherited Create;
  FMultiFormatReader := GetMultiFormatReader(format, additionalHints);
end;

destructor TScanManager.Destroy;
begin
  FMultiFormatReader.Free;
  inherited;
end;

function TScanManager.GetMultiFormatReader(format: TBarcodeFormat;
  additionalHints: TDictionary<TDecodeHintType, TObject>): TMultiFormatReader;

var
  listFormats: TList<TBarcodeFormat>;
  ahKey: TDecodeHintType;
  ahValue: TObject;
  hints: TDictionary<TDecodeHintType, TObject>;
begin

  Result := TMultiFormatReader.Create;
  hints := TDictionary<TDecodeHintType, TObject>.Create;

  if (format <> TBarcodeFormat.Auto) then
  begin

    listFormats := TList<TBarcodeFormat>.Create();
    listFormats.Add(format);

    hints.Add(DecodeHintType.POSSIBLE_FORMATS, listFormats);

  end;

  if (additionalHints <> nil) then
  begin

    for ahKey in additionalHints.Keys do
    begin
      ahValue := additionalHints[ahKey];
      hints.Add(ahKey, ahValue);
    end;

  end;

  Result.hints := hints;

end;

end.
