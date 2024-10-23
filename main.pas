unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Buttons, MPlayerCtrl, fphttpclient, fpjson, jsonparser, DateUtils,
  opensslsockets, Bass, about, fpimage, fpreadpng;

type
  TTrack = class
  public
    ID: Integer;
    Title: String;
    Artist: String;
    Filename: String;
    Date: String;
    UserID: Integer;
    Username: String;
    Notes: String;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    AboutBtn: TButton;
    TrNotes: TMemo;
    PlaybackControl: TBitBtn;
    lstTracks: TListBox;
    Timer1: TTimer;
    TrackBar1: TTrackBar;
    TrArtist: TLabel;
    TrName: TLabel;
    TrPos: TLabel;
    TrUploadedBy: TLabel;
    procedure AboutBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lstTracksClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
  private
    procedure FetchTracks;
    procedure ParseTrackList(const JSONString: String);
    procedure ShowTrackDetails(Track: TTrack);
    procedure LoadGlyph(BitBtn: TBitBtn; const FilePath: string);
    function GetTracks(const URL: String): String;
    function AudioTime(seconds: LongInt): AnsiString;
  public

  end;

var
  Form1: TForm1;
  Stream: HSTREAM;
  AudioURL: String;
  InstanceURL: String;
  UpdPos: Boolean;
  IsPlaying: Boolean;
  PlayingID: String;
  SelTrID: String;
implementation

{$R *.lfm}

var
  TrackList: TList;

{ TForm1 }

procedure TForm1.AboutBtnClick(Sender: TObject);
begin
  AboutForm.ShowModal;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadGlyph(PlaybackControl, './images/play.png');
  Form1.Left := (Screen.WorkAreaRect.Width  - Form1.Width)  div 2;
  Form1.Top  := (Screen.WorkAreaRect.Height - Form1.Height) div 2;
  InstanceURL := 'https://koke228.ru';
  IsPlaying := False;
  FetchTracks;
  if BASS_Init(-1, 44100, 0, 0, nil) <> True then
  begin
  ShowMessage('Ошибка инициализации Bass. Воспроизведение, вероятнее всего, не будет работать.');
  end;
end;

procedure TForm1.lstTracksClick(Sender: TObject);
var
  Track: TTrack;
begin
  if lstTracks.ItemIndex <> -1 then
  begin
    Track := TTrack(TrackList[lstTracks.ItemIndex]);
    ShowTrackDetails(Track);
    SelTrID := IntToStr(Track.ID);
  end;
  if SelTrID <> PlayingID then
  begin
    LoadGlyph(PlaybackControl, './images/play.png');
  end
  else
  begin
    LoadGlyph(PlaybackControl, './images/pause.png');
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  pos: QWORD;
  seconds, length: Double;
begin
  UpdPos := True;
  pos := BASS_ChannelGetPosition(Stream, BASS_POS_BYTE);
  seconds := BASS_ChannelBytes2Seconds(Stream, pos);
  length := BASS_ChannelBytes2Seconds(Stream, BASS_ChannelGetLength(Stream, BASS_POS_BYTE));
  if seconds = length then BASS_ChannelStop(Stream);
  TrPos.Caption := AudioTime(Round(seconds))+' / '+AudioTime(Round(length));
  TrackBar1.Position := Trunc(seconds);
  UpdPos := False;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
var
  pos: QWORD;
begin
  if UpdPos <> True then
  begin
    pos := BASS_ChannelSeconds2Bytes(Stream, TrackBar1.Position);
    BASS_ChannelSetPosition(Stream, pos, BASS_POS_BYTE);
  end;
end;

procedure TForm1.ShowTrackDetails(Track: TTrack);
begin
  SelTrID := IntToStr(Track.ID);
  PlaybackControl.Visible := True;
  TrName.Caption := 'Название: '+Track.Title;
  TrArtist.Caption := 'Исполнитель: '+Track.Artist;
  AudioURL := InstanceURL+'/static/audio/'+Track.Filename;
  TrUploadedBy.Caption := 'Загружено: '+Track.Username+' '+Track.Date;
  if track.notes <> '' then
     begin
     TrNotes.Lines.Text := 'Примечания: '+Track.Notes;
     end
  else
     begin
     TrNotes.Lines.Text := '';
     end

end;

procedure TForm1.LoadGlyph(BitBtn: TBitBtn; const FilePath: string);
var
  Picture: TPicture;
begin
  Picture := TPicture.Create;
  try
    Picture.LoadFromFile(FilePath);
    BitBtn.Glyph.Assign(Picture.Graphic);
  finally
    Picture.Free;
  end;
end;

procedure TForm1.FetchTracks;
var
  Response: String;
begin
  Response := GetTracks(InstanceURL+'/anusaudio/api/get_tracks');
  ParseTrackList(Response);
end;

function TForm1.GetTracks(const URL: String): String;
var
  HTTPClient: TFPHTTPClient;
begin
  HTTPClient := TFPHTTPClient.Create(nil);
  try
    Result := HTTPClient.Get(URL);
  finally
    HTTPClient.Free;
  end;
end;

procedure TForm1.ParseTrackList(const JSONString: String);
var
  JSONData: TJSONData;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  i: Integer;
  Track: TTrack;
begin
  TrackList.Clear;
  lstTracks.Clear;

  JSONData := GetJSON(JSONString);
  try
    JSONArray := TJSONArray(JSONData);
    for i := 0 to JSONArray.Count - 1 do
    begin
      JSONObject := JSONArray.Objects[i];
      Track := TTrack.Create;
      Track.Title := JSONObject.Get('title', '');
      Track.Artist := JSONObject.Get('artist', '');
      Track.Filename := JSONObject.Get('filename', '');
      Track.Date := JSONObject.Get('date_posted', '');
      Track.Username := JSONObject.Get('username', '');
      Track.Notes := JSONObject.Get('notes', '');
      Track.ID := JSONObject.Get('id', 1);
      TrackList.Add(Track);
      lstTracks.Items.Add(Format('%s - %s', [Track.Artist, Track.Title]));
    end;
  finally
    JSONData.Free;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if IsPlaying = True then
     begin
    if Stream <> 0 then
       begin
           BASS_ChannelPause(Stream);
           IsPlaying := False;
           LoadGlyph(PlaybackControl, './images/play.png');
       end
    end
  else
  if IsPlaying = False then
     begin
    if Stream <> 0 then
       begin
           BASS_ChannelPlay(Stream, False);
           IsPlaying := True;
           LoadGlyph(PlaybackControl, './images/pause.png');
       end;
    end;
   if Stream = 0 then
    begin
      Stream := BASS_StreamCreateURL(PChar(AudioURL), 0, 0, nil, nil);
      if Stream = 0 then
      begin
        ShowMessage('Ошибка загрузки аудио');
      end
      else
      begin
        PlayingId := SelTrID;
        IsPlaying := True;
        TrackBar1.Max := Round(BASS_ChannelBytes2Seconds(Stream, BASS_ChannelGetLength(Stream, BASS_POS_BYTE)));
        BASS_ChannelPlay(Stream, False);
        LoadGlyph(PlaybackControl, './images/pause.png');
      end
end;
   if PlayingID <> SelTrID then
      begin
        BASS_ChannelStop(Stream);
        Stream := BASS_StreamCreateURL(PChar(AudioURL), 0, 0, nil, nil);
        if Stream = 0 then
        begin
          ShowMessage('Ошибка загрузки аудио');
        end
        else
        begin
          PlayingId := SelTrID;
          IsPlaying := True;
          TrackBar1.Max := Round(BASS_ChannelBytes2Seconds(Stream, BASS_ChannelGetLength(Stream, BASS_POS_BYTE)));
          BASS_ChannelPlay(Stream, False);
          LoadGlyph(PlaybackControl, './images/pause.png');
        end
   end;
end;

function TForm1.AudioTime(seconds: LongInt): AnsiString;
var
  minutes, secs: Integer;
begin
  minutes := seconds div 60;
  secs := seconds mod 60;
  Result := Format('%.2d:%.2d', [minutes, secs]);
end;

initialization
  TrackList := TList.Create;

finalization
  while TrackList.Count > 0 do
  begin
    TObject(TrackList[0]).Free;
    TrackList.Delete(0);
  end;
  TrackList.Free;

end.

