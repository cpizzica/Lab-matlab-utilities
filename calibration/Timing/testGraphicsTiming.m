% testGraphicsTiming
%
% Shows a bunch of targets (top) or RDK (bottom) of increasing complexity &
% tests for skipped frames

SCREEN_INDEX  = 1;  % 0=small rectangle on main screen; 1=main screen; 2=secondary

%% TARGETS
%
dotsTheScreen.reset();
s = dotsTheScreen.theObject;
s.displayIndex = SCREEN_INDEX;
dotsTheScreen.openWindow();
frameInt = 1./s.windowFrameRate.*1000; % in ms

% draw in screen rect
screenHoriz = s.displayPixels(3)./2./s.pixelsPerDegree;
screenVert  = s.displayPixels(4)./2./s.pixelsPerDegree;

% make target(s) & store timing data
NTS        = [50 500:500:5000];
numTs      = length(NTS);
NUM_FRAMES = 50;
timeData   = nans(NUM_FRAMES, numTs);
for nn = 1:numTs;
    numTargets = NTS(nn);
    t = dotsDrawableTargets();
    t.xCenter = rand(numTargets, 1).*screenHoriz.*2-screenHoriz;
    t.yCenter = rand(numTargets, 1).*screenVert.*2-screenVert;
    t.width   = 0.7;
    t.height  = 0.7;
    t.colors  = rand(numTargets, 3);
    
    % draw 'em
    
    startTime = mglGetSecs();
    for ii = 1:NUM_FRAMES
        t.xCenter = t.xCenter + rand(numTargets,1)-0.5;
        t.yCenter = t.yCenter + rand(numTargets,1)-0.5;
        Lwrap     = abs(t.xCenter) > screenHoriz | abs(t.yCenter) > screenVert;
        t.xCenter(Lwrap) = rand(sum(Lwrap), 1).*screenHoriz.*2-screenHoriz;
        t.yCenter(Lwrap) = rand(sum(Lwrap), 1).*screenVert.*2-screenVert;
        dotsDrawable.drawFrame({t});
        timeData(ii,nn) = (mglGetSecs - startTime).*1000;
    end
    s.blank();
end

dotsTheScreen.closeWindow();

figure
subplot(2,1,1); cla reset; hold on;
plot(NTS, sum(diff(timeData)>frameInt+2), 'k.', 'MarkerSize', 8)
axis([NTS(1) NTS(end) -1 NUM_FRAMES+1])


%% RDK
%
dotsTheScreen.reset();
s = dotsTheScreen.theObject;
s.displayIndex = SCREEN_INDEX;
dotsTheScreen.openWindow();
frameInt = 1./s.windowFrameRate.*1000; % in ms

% make dots & store timing data
DDS        = 1000:2000:20000;
numDDs     = length(DDS);
NUM_FRAMES = 50;
timeData2  = nans(NUM_FRAMES, numDDs);
dots       = dotsDrawableDotKinetogram();
dots.diameter  = 15;
dots.pixelSize = 3;
for nn = 1:numDDs;    
    % draw 'em
    dots.density   = DDS(nn);
    dots.isVisible = true;
    startTime = mglGetSecs();
    dots.prepareToDrawInWindow();
    for ii = 1:NUM_FRAMES
        dotsDrawable.drawFrame({dots}, true);
        timeData2(ii,nn) = (mglGetSecs - startTime).*1000;
    end
    s.blank();
end

dotsTheScreen.closeWindow();

subplot(2,1,2); cla reset; hold on;
plot(DDS([1 end]), [0 0], 'k:');
plot(DDS, sum(diff(timeData2)>frameInt+2), 'k.', 'MarkerSize', 8)
axis([DDS(1) DDS(end) -1 NUM_FRAMES+1])


