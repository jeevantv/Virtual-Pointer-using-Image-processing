function MouseControl(redThresh, greenThresh, blueThresh, numFrame)
warning('off','vision:transition:usesOldCoordinates');
%% Initialization
if nargin < 1 %Number of functions input aruments
    redThresh = 0.24;  % Threshold for Red color detection
    greenThresh = 0.05; % Threshold for green color detection
    blueThresh = 0.15; % Threshold for blue color detection
    numFrame = 3000; % Total number of frames duration
end
cam = imaqhwinfo; % Get Camera information
cameraName = char(cam.InstalledAdaptors(end));
cameraInfo = imaqhwinfo(cameraName);
cameraId = cameraInfo.DeviceInfo.DeviceID(end);
cameraFormat = char(cameraInfo.DeviceInfo.SupportedFormats(end));
jRobot = java.awt.Robot; % Initialize the JAVA robot
vidDevice = imaq.VideoDevice(cameraName, cameraId, cameraFormat, ... % Input Video from current adapter
                    'ReturnedColorSpace', 'RGB'); %it will return colours in viedo i,e RGB
vidInfo = imaqhwinfo(vidDevice);  % Acquire video information
screenSize = get(0,'ScreenSize'); % Acquire system screensize

hblob = vision.BlobAnalysis('AreaOutputPort', false, ... % Setup blob analysis handling
                                'CentroidOutputPort', true, ... 
                                'BoundingBoxOutputPort', true', ...
                                'MaximumBlobArea', 3000, ...
                                'MinimumBlobArea', 100, ...
                                'MaximumCount', 3);
hshapeinsBox = vision.ShapeInserter('BorderColorSource', 'Input port', ... % Setup colored box handling
                                    'Fill', true, ...
                                    'FillColorSource', 'Input port', ...
                                    'Opacity', 0.4);
hVideoIn = vision.VideoPlayer('Name', 'Final Video', ... % Setup output video stream handling
                                'Position', [100 100 vidInfo.MaxWidth+20 vidInfo.MaxHeight+30]); %800 500
nFrame = 0; % Initializing variables
lCount = 0; rCount = 0; dCount = 0;
sureEvent = 5;
iPos = vidInfo.MaxWidth/2;
%% Frame Processing Loop
while (nFrame < numFrame)
    rgbFrame = step(vidDevice); % Acquire single frame
    rgbFrame = flipdim(rgbFrame,2); % Flip the frame for userfriendliness
    diffFrameRed = imsubtract(rgbFrame(:,:,1), rgb2gray(rgbFrame)); % Get red components of the image
    binFrameRed = im2bw(diffFrameRed, redThresh); % Convert the image into binary image with the red objects as white
    [centroidRed, bboxRed] = step(hblob, binFrameRed); % Get the centroids and bounding boxes of the red blobs
    diffFrameGreen = imsubtract(rgbFrame(:,:,2), rgb2gray(rgbFrame)); % Get green components of the image
    binFrameGreen = im2bw(diffFrameGreen, greenThresh); % Convert the image into binary image with the green objects as white
    [centroidGreen, bboxGreen] = step(hblob, binFrameGreen); % Get the centroids and bounding boxes of the blue blobs
    
    diffFrameBlue = imsubtract(rgbFrame(:,:,3), rgb2gray(rgbFrame)); % Get blue components of the image
    binFrameBlue = im2bw(diffFrameBlue, blueThresh); % Convert the image into binary image with the blue objects as white
    [~, bboxBlue] = step(hblob, binFrameBlue); % Get the centroids and bounding boxes of the blue blobs
    
    if length(bboxRed(:,1)) == 1 % Mouse pointer movement routine
        jRobot.mouseMove(1.5*centroidRed(:,1)*screenSize(3)/vidInfo.MaxWidth, 1.5*centroidRed(:,2)*screenSize(4)/vidInfo.MaxHeight);
    end
    if ~isempty(bboxBlue(:,1)) % Left Click, Right Click, Double Click routine
        if length(bboxBlue(:,1)) == 1 % Left Click routine
            lCount = lCount + 1;
            if lCount == sureEvent % Make sure of the left click event
                jRobot.mousePress(16);
                pause(1);
                jRobot.mouseRelease(16);
            end
        elseif length(bboxBlue(:,1)) == 2 % Right Click routine
            rCount = rCount + 1;
            if rCount == sureEvent % Make sure of the right click event
                jRobot.mousePress(4);
                pause(1);
                jRobot.mouseRelease(4);
            end 
        elseif length(bboxBlue(:,1)) == 3 % Double Click routine
            dCount = dCount + 1;
            if dCount == sureEvent % Make sure of the double click event
                jRobot.mousePress(16);
                pause(1);
                jRobot.mouseRelease(16);
                pause(1);
                jRobot.mousePress(16);
                pause(1);
                jRobot.mouseRelease(16);
            end 
        end
    else
        lCount = 0; rCount = 0; dCount = 0; % Reset the sureEvent counter
    end
    if ~isempty(bboxGreen(:,1)) % Scroll event routine
        if (mean(centroidGreen(:,2)) - iPos) < -2
            jRobot.mouseWheel(-1);
        elseif (mean(centroidGreen(:,2)) - iPos) > 2
            jRobot.mouseWheel(1);
        end
        iPos = mean(centroidGreen(:,2));
    end
    vidIn = step(hshapeinsBox, rgbFrame, bboxRed,single([1 0 0])); % Show the red objects in output stream
    vidIn = step(hshapeinsBox, vidIn, bboxGreen,single([0 1 0])); % Show the green objects in output stream
    vidIn = step(hshapeinsBox, vidIn, bboxBlue,single([0 0 1])); % Show the blue objects in output stream
    step(hVideoIn, vidIn); % Output video stream
    nFrame = nFrame+1;
   imshow(binFrameRed) %masking of red
   imshow(binFrameBlue) %masking of blue
   imshow(binFrameGreen) %masking of green
   
end
%% Clearing Memory
release(hVideoIn); % Release all memory and buffer used
release(vidDevice);
clc;
%system('c:\windows\system32\mspaint.exe')
end