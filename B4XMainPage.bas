B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=Project.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private btnLoadImage As B4XView
	Private pipe As MediaPipe
	'''Private bmp As Bitmap
	Private ImageView1 As ImageView
	Private ocv As OCVOpenCVLoader
	Private pnlCamera As Panel
	Private cam As CamEx2
	Private rp As RuntimePermissions
	Private MyTaskIndex As Int
	Private frontCamera As Boolean = False
	Private VideoMode As Boolean = False
	Private VideoFileDir, VideoFileName As String
	Private detectTimer As Timer
	Private bmp2 As Bitmap
	Private btnTakePicture As Button
	Private pnlBackground As B4XView
End Sub

Public Sub Initialize
	B4XPages.GetManager.LogEvents = True
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	btnTakePicture.Color = xui.Color_Transparent
	VideoFileDir = rp.GetSafeDirDefaultExternal("")
	VideoFileName = "1.mp4"
	File.Copy(File.DirAssets, "pose_landmarker_full.task", File.DirInternal, "pose_landmarker_full.task")
	'''bmp.InitializeResize(File.DirAssets, "delmy.jpg", 480dip, 800dip, True)
'''	rp.CheckAndRequest(rp.PERMISSION_CAMERA)
	detectTimer.Initialize("detect", 500)
	'''bmp2.Initialize(File.DirAssets, "delmy.jpg")
	'''bmp2.InitializeResize(File.DirAssets, "papi.jpg", 480dip, 800dip, True)
	'''ImageView1.Bitmap = bmp2
	
End Sub

Sub B4XPage_Appear
	cam.Initialize(pnlCamera)
	OpenCamera(frontCamera)
End Sub

Sub B4XPage_Disappear
	cam.Stop
End Sub

'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.

Sub OpenCamera (front As Boolean)
	'''Dim permissions As List
	'''permissions = Array(rp.PERMISSION_CAMERA, rp.PERMISSION_WRITE_EXTERNAL_STORAGE)
	rp.CheckAndRequest(rp.PERMISSION_CAMERA)
	'''Wait For Activity_PermissionResult (Permission As String, Result As Boolean)
	'''For Each per As String In permissions
	'''rp.CheckAndRequest(per)
	Wait For B4XPage_PermissionResult (permission As String, Result As Boolean)
	If Result = False Then
		ToastMessageShow("No permission!", True)
		Return
	End If
	
	rp.CheckAndRequest(rp.PERMISSION_RECORD_AUDIO)
	Wait For B4XPage_PermissionResult (permission As String, Result As Boolean)
	If Result = False Then
		ToastMessageShow("No permission!", True)
		VideoMode = False
	End If
	'''Next
	'''cam.Initialize(pnlCamera)
	'''	SetState(False, False, VideoMode)
	'''If retries > 0 And retries = 2 Then Return
	Wait For (cam.OpenCamera(front)) Complete (TaskIndex As Int)
	If TaskIndex > 0 Then
		MyTaskIndex = TaskIndex 'hold this index. It will be required in later calls.
		Wait For(PrepareSurface) Complete (Success As Boolean)
''''		Log($"starter.picturenumber ${Starter.pictureNumber}"$)
''''		If Starter.pictureNumber = 1 Then
''''			lblTitle.Text = "Take a back-view photo"
''''			If lblTitle.Visible = False Then lblTitle.Visible = True
''''		Else
''''			lblTitle.Text = "Take a side-view photo"
''''			If lblTitle.Visible = False Then lblTitle.Visible = True
''''		End If
	Else
		
		OpenCamera(False)
'''		retries = retries + 1
'''		LogColor("retries: " & retries, xui.Color_Blue)
	End If
	Log("Start success: " & Success)
	'''	SetState(Success, False, VideoMode)
	If Success = False Then
		ToastMessageShow("Failed to open camera", True)
	End If'''
End Sub

Sub PrepareSurface As ResumableSub
	'''SetState(False, busystate, VideoMode)
	'sizes can be modified here
	If VideoMode Then
		Log("starting video mode")
		cam.PreviewSize.Initialize(640, 480)
		'Using a temporary file to store the video.
		'''cam.PreviewSize.Initialize(640, 480)
		ResizePreviewPanelBasedPreviewSize
		'Using a temporary file to store the video.
		Wait For (cam.PrepareSurfaceForVideo(MyTaskIndex, VideoFileDir, "temp-" & VideoFileName)) Complete (Success As Boolean)
		Log("surface prepared: " & Success)
	Else
		cam.PreviewSize.Initialize(1920, 1080)
		Wait For (cam.PrepareSurface(MyTaskIndex)) Complete (Success As Boolean)
	End If
	If Success Then 
		cam.StartPreview(MyTaskIndex, VideoMode)
		'''detectTimer.Enabled = True
'''		pipe.Initialize("pipe", "pose_landmarker_full.task")
'''		pipe.processPosseLandmarks(0.5, 0.5, 0.5)
'''		ImageView1.Color = Colors.Transparent
'''		ImageView1.BringToFront
	End If
	'''	SetState(Success, busystate, VideoMode)
	Return Success
End Sub

Private Sub ResizePreviewPanelBasedPreviewSize
	Dim pw = cam.PreviewSize.Height, ph = cam.PreviewSize.Width As Int
	Dim r As Float = Max(Root.Width / pw, Root.Height / ph)  'FILL_NO_DISTORTIONS (change to Min for FIT)
	Dim w As Int = pw * r
	Dim h As Int = ph * r
	pnlCamera.SetLayoutAnimated(0, Round(Root.Width / 2 - w / 2), Round(Root.Height / 2 - h / 2), Round(w), Round(h))
End Sub

'''Public Sub DataAvailable(bmp As Bitmap)
'''	'''Dim bmp As Bitmap = cam.DataToBitmap(data)
''''''	pipe.processPosseLandmarks(bmp, 0.5, 0.5, 0.5)
'''	'''processLandmarks(bmp)
'''	Try
'''		bmp2 = bmp
'''	pipe.processImage(bmp)
'''	Catch
'''		Log("problem: " & LastException)
'''	End Try
'''End Sub

Sub pipe_ResultsAvailable (LandMarks As List)
	LogColor("results: " & LandMarks.Size, xui.Color_Blue)
	Dim nose As NormalizedLandmark = LandMarks.Get(0)
	Dim righteye As NormalizedLandmark = LandMarks.Get(5)
	Dim leftfoot As NormalizedLandmark = LandMarks.Get(31)
	Dim rightfoot As NormalizedLandmark = LandMarks.Get(32)
	Dim mouth As NormalizedLandmark = LandMarks.Get(9)
	Dim cnv As Canvas
	cnv.Initialize(ImageView1)
	Dim rect As Rect
	rect.Initialize(0, 0, 100%x, 100%y)
	cnv.DrawRect(rect, xui.Color_Transparent, False, 0)
	'''cnv.Initialize2(bmp)
	Dim originalwidth As Int
	Dim originalheight As Int
	originalwidth = bmp2.Width
	originalheight = bmp2.Height
	Dim displayedwidth As Int = pnlCamera.Width '''ImageView1.Width
	Dim displayedheight As Int = pnlCamera.Height '''ImageView1.Height
	
	Dim originalAspectRatio As Float = originalwidth / originalheight
	Dim displayedAspectRatio As Float = displayedwidth / displayedheight
	
	Dim scaleFactor As Float
	Dim offsetX, offsetY As Float
	If (originalAspectRatio > displayedAspectRatio) Then
		scaleFactor = displayedwidth / originalwidth
		offsetY = (displayedheight - (originalheight * scaleFactor)) /2
	Else
		scaleFactor = displayedheight / originalwidth
		offsetX = (displayedwidth - (originalwidth * scaleFactor)) / 2
	End If
	
	Dim nosex As Float = nose.getX * displayedwidth   '''* originalwidth * scaleFactor + offsetX
	Dim nosey As Float = nose.getY * displayedheight   '''* originalheight * scaleFactor + offsetY
	
	cnv.DrawCircle(nosex, nosey, 5dip, xui.Color_Yellow, True, 2)
End Sub

Sub pipe_Error (message As String)
	LogColor("error: " & message, xui.Color_Red)
End Sub

private Sub processLandmarks(bmp As Bitmap)
	Dim markers As List
	markers = pipe.getMarkers
	'''Log("markers size: " & markers.Size)
	If markers.IsInitialized And markers.Size > 0 Then
	Dim nose As NormalizedLandmark = markers.Get(0)
	Dim righteye As NormalizedLandmark = markers.Get(5)
	Dim leftfoot As NormalizedLandmark = markers.Get(31)
	Dim rightfoot As NormalizedLandmark = markers.Get(32)
	Dim mouth As NormalizedLandmark = markers.Get(9)
	Dim cnv As Canvas
	cnv.Initialize(ImageView1)
	Dim rect As Rect
	rect.Initialize(0, 0, 100%x, 100%y)
	cnv.DrawRect(rect, xui.Color_Transparent, False, 0)
	'''cnv.Initialize2(bmp)
	Dim originalwidth As Int
	Dim originalheight As Int
	originalwidth = bmp.Width
	originalheight = bmp.Height
	Dim displayedwidth As Int = pnlCamera.Width '''ImageView1.Width
	Dim displayedheight As Int = pnlCamera.Height '''ImageView1.Height
	
	Dim originalAspectRatio As Float = originalwidth / originalheight
	Dim displayedAspectRatio As Float = displayedwidth / displayedheight
	
	Dim scaleFactor As Float
	Dim offsetX, offsetY As Float
	If (originalAspectRatio > displayedAspectRatio) Then
		scaleFactor = displayedwidth / originalwidth
		offsetY = (displayedheight - (originalheight * scaleFactor)) /2
	Else
		scaleFactor = displayedheight / originalwidth
		offsetX = (displayedwidth - (originalwidth * scaleFactor)) / 2
	End If
	
	Dim nosex As Float = nose.getX * displayedwidth   '''* originalwidth * scaleFactor + offsetX
	Dim nosey As Float = nose.getY * displayedheight   '''* originalheight * scaleFactor + offsetY
	Dim leftfootx As Float = leftfoot.getX * displayedwidth
	Dim leftfooty As Float = leftfoot.getY * displayedheight
	Dim rightfootx As Float = rightfoot.getX * displayedwidth
	Dim rightfooty As Float = rightfoot.getY * displayedheight
	Dim mouthx As Float = mouth.getX * displayedwidth
	Dim mouthy As Float = mouth.getY * displayedheight
	Dim righteyex As Float = righteye.getX * displayedwidth
	Dim righteyey As Float = righteye.getY * displayedheight
	
	cnv.DrawCircle(nosex, nosey, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(leftfootx, leftfooty, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(rightfootx, rightfooty, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(mouthx, mouthy, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(righteyex, righteyey, 5dip, xui.Color_Yellow, True, 2)
	End If
End Sub

Sub detect_Tick
	Dim prevbmp As Bitmap
	prevbmp = cam.GetPreviewBitmap(1920, 1080)
	Log("prevbmp: " & prevbmp.Width & " / " & prevbmp.Height)
	Try
		'''pipe.Initialize("pipe", prevbmp, "pose_landmarker_full.task", 0.5, 0.5, 0.5)

	Dim markers As List
	markers = pipe.getMarkers
	Log("markers size: " & markers.Size)
	Dim nose As NormalizedLandmark = markers.Get(0)
	Dim righteye As NormalizedLandmark = markers.Get(5)
	Dim leftfoot As NormalizedLandmark = markers.Get(31)
	Dim rightfoot As NormalizedLandmark = markers.Get(32)
	Dim mouth As NormalizedLandmark = markers.Get(9)
	Dim cnv As Canvas
	cnv.Initialize(ImageView1)
	'''cnv.Initialize2(bmp)
	Dim originalwidth As Int
	Dim originalheight As Int
	originalwidth = prevbmp.Width
	originalheight = prevbmp.Height
	Dim displayedwidth As Int = pnlCamera.Width '''ImageView1.Width
	Dim displayedheight As Int = pnlCamera.Height '''ImageView1.Height
	
	Dim originalAspectRatio As Float = originalwidth / originalheight
	Dim displayedAspectRatio As Float = displayedwidth / displayedheight
	
	Dim scaleFactor As Float
	Dim offsetX, offsetY As Float
	If (originalAspectRatio > displayedAspectRatio) Then
		scaleFactor = displayedwidth / originalwidth
		offsetY = (displayedheight - (originalheight * scaleFactor)) /2
	Else
		scaleFactor = displayedheight / originalwidth
		offsetX = (displayedwidth - (originalwidth * scaleFactor)) / 2
	End If
	
	Dim nosex As Float = nose.getX * displayedwidth   '''* originalwidth * scaleFactor + offsetX
	Dim nosey As Float = nose.getY * displayedheight   '''* originalheight * scaleFactor + offsetY
	Dim leftfootx As Float = leftfoot.getX * displayedwidth
	Dim leftfooty As Float = leftfoot.getY * displayedheight
	Dim rightfootx As Float = rightfoot.getX * displayedwidth
	Dim rightfooty As Float = rightfoot.getY * displayedheight
	Dim mouthx As Float = mouth.getX * displayedwidth
	Dim mouthy As Float = mouth.getY * displayedheight
	Dim righteyex As Float = righteye.getX * displayedwidth
	Dim righteyey As Float = righteye.getY * displayedheight
	
	cnv.DrawCircle(nosex, nosey, 5dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(leftfootx, leftfooty, 5dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(rightfootx, rightfooty, 5dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(mouthx, mouthy, 5dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(righteyex, righteyey, 5dip, xui.Color_Yellow, True, 2)
	'''ImageView1.Bitmap = cnv.Bitmap
	
'''	For Each mark As NormalizedLandmark In markers
'''		Log("mark.x: " & mark.getX)
'''		Log("mark.Y: " & mark.getY)
'''	Next
	
	Catch
		Log("Error: " & LastException)
	End Try
End Sub


Private Sub btnLoadImage_Click
'''	Try
'''		pipe.Initialize("pipe", bmp, "pose_landmarker_full.task", 0.5, 0.5, 0.5)
'''	Catch
'''		Log("Error: " & LastException)
'''	End Try
'''	Dim markers As List
'''	markers = pipe.getMarkers
'''	Log("markers size: " & markers.Size)
'''	Dim nose As NormalizedLandmark = markers.Get(0)
'''	Dim righteye As NormalizedLandmark = markers.Get(5)
'''	Dim leftfoot As NormalizedLandmark = markers.Get(31)
'''	Dim rightfoot As NormalizedLandmark = markers.Get(32)
'''	Dim mouth As NormalizedLandmark = markers.Get(9)
'''	Dim cnv As Canvas
'''	cnv.Initialize(ImageView1)
'''	'''cnv.Initialize2(bmp)
'''	Dim originalwidth As Int
'''	Dim originalheight As Int
'''	originalwidth = bmp.Width
'''	originalheight = bmp.Height
'''	Dim displayedwidth As Int = ImageView1.Width
'''	Dim displayedheight As Int = ImageView1.Height
'''	
'''	Dim originalAspectRatio As Float = originalwidth / originalheight
'''	Dim displayedAspectRatio As Float = displayedwidth / displayedheight
'''	
'''	Dim scaleFactor As Float
'''	Dim offsetX, offsetY As Float
'''	If (originalAspectRatio > displayedAspectRatio) Then
'''		scaleFactor = displayedwidth / originalwidth
'''		offsetY = (displayedheight - (originalheight * scaleFactor)) /2
'''	Else
'''		scaleFactor = displayedheight / originalwidth
'''		offsetX = (displayedwidth - (originalwidth * scaleFactor)) / 2
'''	End If
'''	
'''	Dim nosex As Float = nose.getX * displayedwidth   '''* originalwidth * scaleFactor + offsetX
'''	Dim nosey As Float = nose.getY * displayedheight   '''* originalheight * scaleFactor + offsetY
'''	Dim leftfootx As Float = leftfoot.getX * displayedwidth
'''	Dim leftfooty As Float = leftfoot.getY * displayedheight
'''	Dim rightfootx As Float = rightfoot.getX * displayedwidth
'''	Dim rightfooty As Float = rightfoot.getY * displayedheight
'''	Dim mouthx As Float = mouth.getX * displayedwidth
'''	Dim mouthy As Float = mouth.getY * displayedheight
'''	Dim righteyex As Float = righteye.getX * displayedwidth
'''	Dim righteyey As Float = righteye.getY * displayedheight
'''	
'''	cnv.DrawCircle(nosex, nosey, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(leftfootx, leftfooty, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(rightfootx, rightfooty, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(mouthx, mouthy, 5dip, xui.Color_Yellow, True, 2)
'''	cnv.DrawCircle(righteyex, righteyey, 5dip, xui.Color_Yellow, True, 2)
'''	'''ImageView1.Bitmap = cnv.Bitmap
'''	
'''	For Each mark As NormalizedLandmark In markers
'''		Log("mark.x: " & mark.getX)
'''		Log("mark.Y: " & mark.getY)
'''	Next

	pipe.Initialize("pipe", "pose_landmarker_heavy.task")
	
	pipe.processPosseImageLandmarks(0.1, 0.1, 0.1)
	pipe.processImage(ImageView1.Bitmap)
	Dim markers As List
	markers = pipe.getMarkers
	Log("markers size: " & markers.Size)
	Dim nose As NormalizedLandmark = markers.Get(0)
	Dim lefteye As NormalizedLandmark = markers.Get(2)
	Dim righteye As NormalizedLandmark = markers.Get(5)
	Dim leftEar As NormalizedLandmark = markers.Get(7)
	Dim rightEar As NormalizedLandmark = markers.Get(8)
	Dim shoulderleft As NormalizedLandmark = markers.Get(11)
	Dim shoulderright As NormalizedLandmark = markers.Get(12)
	Dim leftmouth As NormalizedLandmark = markers.Get(9)
	Dim rightmouth As NormalizedLandmark = markers.Get(10)
	Dim leftHill As NormalizedLandmark = markers.Get(29)
	Dim rightHill As NormalizedLandmark = markers.Get(30)
'''	Dim leftfoot As NormalizedLandmark = markers.Get(31)
'''	Dim rightfoot As NormalizedLandmark = markers.Get(32)
'''	Dim mouth As NormalizedLandmark = markers.Get(9)
	Dim cnv As Canvas
	cnv.Initialize(ImageView1)
	
'''	Dim originalwidth As Int
'''	Dim originalheight As Int
'''	originalwidth = bmp2.Width
'''	originalheight = bmp2.Height
	Dim displayedwidth As Int = ImageView1.Width
	Dim displayedheight As Int = ImageView1.Height
	
	
'''	Dim originalAspectRatio As Float = originalwidth / originalheight
'''	Dim displayedAspectRatio As Float = displayedwidth / displayedheight
	
	Dim nosex As Float = nose.getX * displayedwidth   '''* originalwidth * scaleFactor + offsetX
	Dim nosey As Float = nose.getY * displayedheight   '''* originalheight * scaleFactor + offsetY
	Dim lefteyex As Float = lefteye.getX * displayedwidth
	Dim lefteyey As Float = lefteye.getY * displayedheight
	Dim righteyex As Float = righteye.getX * displayedwidth
	Dim righteyey As Float = righteye.getY * displayedheight
	Dim leftMouthX As Float = leftmouth.getX * displayedwidth
	Dim leftMouthY As Float = leftmouth.getY * displayedheight
	Dim rightMouthX As Float = rightmouth.getX * displayedwidth
	Dim rightMouthY As Float = rightmouth.getY * displayedheight
	Dim leftHillX As Float = leftHill.getX * displayedwidth
	Dim leftHillY As Float = leftHill.getY * displayedheight
	Dim rightHillX As Float = rightHill.getX * displayedwidth
	Dim rightHillY As Float = rightHill.getY * displayedheight
	Dim leftEarX As Float = leftEar.getX * displayedwidth
	Dim leftEarY As Float = leftEar.getY * displayedheight
	Dim rightEarX As Float = rightEar.getX * displayedwidth
	Dim rightEarY As Float = rightEar.getY * displayedheight	
	Dim neckleftx As Float = shoulderleft.getX * displayedwidth
	Dim necklefty As Float = shoulderleft.getY * displayedheight
	Dim neckrightx As Float = shoulderright.getX * displayedwidth
	Dim neckrighty As Float = shoulderright.getY * displayedheight
	
	'''Dim eyecenterY As Float = (lefteyey + righteyey) / 2
	Dim neckCenterY As Float = Abs(shoulderleft.getY - shoulderright.gety)
	neckCenterY = neckCenterY * displayedheight
	Dim neckCenterX As Float = Abs(shoulderleft.getX - shoulderright.getX)
	neckCenterX = neckCenterX * displayedwidth
	
	Dim centerMouthX As Float = Abs(leftMouthX - rightMouthX)
	Dim centerMouthY As Float = Abs(leftMouthY - rightMouthY)
	
	Dim topofHead As NormalizedLandmark = estimateTopofHead(leftEar, rightEar, shoulderleft, shoulderright)
	Dim topofHeadX As Float = topofHead.getX * displayedwidth
	Dim topofHeadY As Float = topofHead.getY * displayedheight
	
	
'''	topofHeadY = topofHeadY * displayedheight
'''	topofHeadX = topofHeadX * displayedwidth
	
'''	Dim leftfootx As Float = leftfoot.getX * displayedwidth
'''	Dim leftfooty As Float = leftfoot.getY * displayedheight
'''	Dim rightfootx As Float = rightfoot.getX * displayedwidth
'''	Dim rightfooty As Float = rightfoot.getY * displayedheight
'''	Dim mouthx As Float = mouth.getX * displayedwidth
'''	Dim mouthy As Float = mouth.getY * displayedheight
'''	Dim righteyex As Float = righteye.getX * displayedwidth
'''	Dim righteyey As Float = righteye.getY * displayedheight
	
	'''cnv.DrawCircle(nosex, nosey, 2dip, xui.Color_Yellow, True, 2)
	'''cnv.DrawCircle(lefteyex, lefteyey, 2dip, xui.Color_Yellow, True, 2)
	'''cnv.DrawCircle(righteyex, righteyey, 2dip, xui.Color_Yellow, True, 2)
	'''cnv.DrawCircle(leftMouthX, leftMouthY, 2dip, xui.Color_Yellow, True, 2)
	'''cnv.DrawCircle(rightMouthX, rightMouthY, 2dip, xui.Color_Yellow, True, 2)
	'''cnv.DrawCircle(nosex, topofHeadY, 2dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(nosex, topofHeadY, 2dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(neckleftx, necklefty, 2dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(neckrightx, neckrighty, 2dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(leftEarX, leftEarY, 2dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(rightEarX, rightEarY, 2dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(leftHillX, leftHillY, 2dip, xui.Color_Yellow, True, 2)
	cnv.DrawCircle(rightHillX, rightHillY, 2dip, xui.Color_Yellow, True, 2)
End Sub

'''        Landmark earMidpoint = CalculateMidPoint(leftEar, rightEar);
'''
'''        // Calculate midpoint between the shoulders
'''        Landmark shoulderMidpoint = CalculateMidPoint(leftShoulder, rightShoulder);
'''
'''        // Calculate vertical distance between ear midpoint And shoulder midpoint
'''        float earToShoulderDistance = earMidpoint.getY() - shoulderMidpoint.getY();
'''
'''        // Estimate the top of the head using 1.5 To 2 times the ear-To-shoulder distance
'''        float topofHeadY = earMidpoint.getY() - 1.75f * earToShoulderDistance;
'''
'''        // The X And Z coordinates of the top of the head are the same As the ear midpoint (directly above it)
'''        Return Landmark.newBuilder()
'''                .setX(earMidpoint.getX())
'''                .setY(topofHeadY)
'''                .setZ(earMidpoint.getZ())
'''                .build();

private Sub estimateTopofHead(leftEar As NormalizedLandmark, rightEar As NormalizedLandmark, leftShoulder As NormalizedLandmark, rightShoulder As NormalizedLandmark) As NormalizedLandmark
	Dim earMidPoint As NormalizedLandmark = CalculateMidPoint(leftEar, rightEar)
	Dim shoulderMidPoint As NormalizedLandmark = CalculateMidPoint(leftShoulder, rightShoulder)
	
	LogColor("earMidPointY: " & earMidPoint.getY, xui.Color_Blue)
	LogColor("shoulderMidPointY: " & shoulderMidPoint.getY, xui.Color_Blue)
	
	
	
	Dim earToShoulderDistance As Float = Abs(earMidPoint.getY - shoulderMidPoint.getY)
	Dim percentage As Float = (earMidPoint.getY + shoulderMidPoint.getY + earToShoulderDistance)
	LogColor("earToShoulderDistance: " & earToShoulderDistance, xui.Color_Blue)
	Dim topofHeadY As Float = earMidPoint.getY - 0.7 * earToShoulderDistance
	
	Dim topofHead As NormalizedLandmark
	topofHead.Initialize(earMidPoint.getX, topofHeadY, earMidPoint.getZ)
	
	'''topofHead.setXYZ(earMidPoint.getX, topofHeadY, earMidPoint.getZ)
	Return topofHead
End Sub

private Sub CalculateMidPoint(leftEar As NormalizedLandmark, rightEar As NormalizedLandmark) As NormalizedLandmark
	Dim x, y, z As Float
	x = (leftEar.getX + rightEar.getX) / 2
	y = (leftEar.getY + rightEar.getY) / 2
	z = (leftEar.getZ + rightEar.getZ) / 2
	
	Dim newLandmark As NormalizedLandmark
	newLandmark.Initialize(x, y, z)
	
	'''newLandmark.setXYZ(x, y, z)
	
	Return newLandmark
End Sub



Private Sub btnTakePicture_Click
	Try
		Log("taking picture....")
		Wait For(cam.FocusAndTakePicture(MyTaskIndex)) Complete (Data() As Byte)
		Log("took picture: " & Data.Length)
		cam.DataToFile(Data, VideoFileDir, "1.jpg")
		Dim bmp As Bitmap = cam.DataToBitmap(Data)
		Log("Picture taken: " & bmp) 'ignore
		cam.Stop
		pnlBackground.SetVisibleAnimated(100, True)
		'''B4XImageView1.Bitmap = RotateJpegIfNeeded(bmp, Data)
		ImageView1.Bitmap = RotateJpegIfNeeded(bmp, Data)
		'''Sleep(4000)
		'''pnlBackground.SetVisibleAnimated(500, False)
	Catch
'''		HandleError(LastException)
		Log(LastException)
	End Try
End Sub

Private Sub RotateJpegIfNeeded (bmp As B4XBitmap, Data() As Byte) As B4XBitmap
	Dim p As Phone
	If p.SdkVersion >= 24 Then
		Dim ExifInterface As JavaObject
		Dim in As InputStream
		in.InitializeFromBytesArray(Data, 0, Data.Length)
		ExifInterface.InitializeNewInstance("android.media.ExifInterface", Array(in))
		Dim orientation As Int = ExifInterface.RunMethod("getAttribute", Array("Orientation"))
		Select orientation
			Case 3  '180
				bmp = bmp.Rotate(180)
			Case 6 '90
				bmp = bmp.Rotate(90)
			Case 8 '270
				bmp = bmp.Rotate(270)
		End Select
		in.Close
	End If
	Return bmp
End Sub