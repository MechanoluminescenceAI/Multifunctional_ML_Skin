clc; clear; close all;

% =========================================================
% INTERACTIVE 3D ML RECONSTRUCTION VIEWER
% =========================================================
% Displays:
%   - 3D point cloud
%   - triangular mesh
%   - reconstructed 3D mechanoluminescence (ML)
%   - 3D effective strain
%

% =========================================================

%% PATHS
projectRoot = fileparts(mfilename('fullpath'));
dataRoot    = fullfile(projectRoot,'data');
dicFile     = fullfile(dataRoot,'DIC3DPPresults.mat');
mlFolder    = fullfile(dataRoot,'ML_images_camera_1');
resultsRoot = fullfile(projectRoot,'results');

if ~isfile(dicFile)
    error('DIC result file not found:\n%s',dicFile);
end
if ~isfolder(mlFolder)
    error('ML image folder not found:\n%s',mlFolder);
end

%% LOAD DATA
S = load(dicFile,'DIC3DPPresults');
if ~isfield(S,'DIC3DPPresults')
    error('DIC3DPPresults was not found in the MAT file.');
end
D = S.DIC3DPPresults;

mlFiles = dir(fullfile(mlFolder,'*.png'));
if isempty(mlFiles)
    error('No PNG ML images found in:\n%s',mlFolder);
end
mlFiles = sortFilesNumeric(mlFiles);

%% FRAME COUNT
nGeom  = numel(D.Points3D_ARBM);
nPts2D = numel(D.DIC2Dinfo.Points);
nStr   = numel(D.Deform.Eeq);
nML    = numel(mlFiles);
nFrames = min([nGeom,nPts2D,nStr,nML]);

if nFrames < 1
    error('No overlapping DIC/ML frames are available.');
end

fprintf('Geometry frames : %d\n',nGeom);
fprintf('2D DIC frames   : %d\n',nPts2D);
fprintf('Strain frames   : %d\n',nStr);
fprintf('ML images       : %d\n',nML);
fprintf('Using frames    : %d\n',nFrames);

%% VALID FACES
F = D.Faces;
P0 = D.Points3D_ARBM{1};
validFaces = all(F >= 1 & F <= size(P0,1),2);
Fplot = F(validFaces,:);

%% FIXED AXIS LIMITS AND GLOBAL STRAIN SCALE
globalAxis = [];
allStrainPct = [];

for frameIdx = 1:nFrames
    P = D.Points3D_ARBM{frameIdx};
    P(:,3) = -P(:,3);

    a = [min(P(:,1)) max(P(:,1)) ...
         min(P(:,2)) max(P(:,2)) ...
         min(P(:,3)) max(P(:,3))];

    if isempty(globalAxis)
        globalAxis = a;
    else
        globalAxis = [min(globalAxis(1),a(1)) max(globalAxis(2),a(2)) ...
                      min(globalAxis(3),a(3)) max(globalAxis(4),a(4)) ...
                      min(globalAxis(5),a(5)) max(globalAxis(6),a(6))];
    end

    eeq = D.Deform.Eeq{frameIdx};
    eeq = eeq(validFaces);
    eeq = eeq(isfinite(eeq))*100;
    allStrainPct = [allStrainPct; eeq(:)]; %#ok<AGROW>
end

padX = 0.02*max(1,globalAxis(2)-globalAxis(1));
padY = 0.02*max(1,globalAxis(4)-globalAxis(3));
padZ = 0.02*max(1,globalAxis(6)-globalAxis(5));

globalAxis = [globalAxis(1)-padX globalAxis(2)+padX ...
              globalAxis(3)-padY globalAxis(4)+padY ...
              globalAxis(5)-padZ globalAxis(6)+padZ];

if isempty(allStrainPct)
    strainLimits = [0 1];
else
    strainLimits = [prctile(allStrainPct,1),prctile(allStrainPct,99)];
    if strainLimits(1) == strainLimits(2)
        strainLimits(2) = strainLimits(1)+eps;
    end
end

%% STATE
st.D = D;
st.mlFiles = mlFiles;
st.mlFolder = mlFolder;
st.nFrames = nFrames;
st.Fplot = Fplot;
st.validFaces = validFaces;
st.globalAxis = globalAxis;
st.strainLimits = strainLimits;
st.frameIdx = 1;
st.mode = 'Reconstructed 3D ML';
st.showAxes = false;
st.showColorbar = true;
st.flipY = true;
st.flipX = false;
st.useOrtho = true;
st.obliqueAz = -45.0059;
st.obliqueEl = 54.3626;
st.videoFPS = 5;
st.exportDPI = 300;
st.resultsRoot = resultsRoot;
st.hasRendered = false;

%% GUI
fig = figure('Name','3D ML Reconstruction Viewer', ...
    'NumberTitle','off','Color','w', ...
    'Position',[120 80 1200 820], ...
    'MenuBar','figure','ToolBar','figure');

ax = axes('Parent',fig,'Position',[0.07 0.12 0.71 0.83]);
st.ax = ax;

uicontrol(fig,'Style','text','String','Display', ...
    'Units','normalized','Position',[0.81 0.91 0.15 0.035], ...
    'BackgroundColor','w','HorizontalAlignment','left','FontWeight','bold');

st.modePopup = uicontrol(fig,'Style','popupmenu', ...
    'String',{'Point cloud','Triangular mesh','Reconstructed 3D ML','Effective strain'}, ...
    'Value',3,'Units','normalized','Position',[0.81 0.865 0.17 0.045], ...
    'Callback',@modeChanged);

st.frameText = uicontrol(fig,'Style','text', ...
    'String',sprintf('Frame 1 / %d',nFrames), ...
    'Units','normalized','Position',[0.81 0.80 0.17 0.035], ...
    'BackgroundColor','w','HorizontalAlignment','left','FontWeight','bold');

st.frameSlider = uicontrol(fig,'Style','slider', ...
    'Min',1,'Max',nFrames,'Value',1, ...
    'SliderStep',[1/max(1,nFrames-1),min(10/max(1,nFrames-1),1)], ...
    'Units','normalized','Position',[0.81 0.755 0.17 0.035], ...
    'Callback',@sliderChanged);

uicontrol(fig,'Style','pushbutton','String','Previous', ...
    'Units','normalized','Position',[0.81 0.705 0.08 0.04], ...
    'Callback',@previousFrame);

uicontrol(fig,'Style','pushbutton','String','Next', ...
    'Units','normalized','Position',[0.90 0.705 0.08 0.04], ...
    'Callback',@nextFrame);

uicontrol(fig,'Style','pushbutton','String','Top view', ...
    'Units','normalized','Position',[0.81 0.635 0.08 0.045], ...
    'Callback',@topView);

uicontrol(fig,'Style','pushbutton','String','Oblique', ...
    'Units','normalized','Position',[0.90 0.635 0.08 0.045], ...
    'Callback',@obliqueView);

uicontrol(fig,'Style','pushbutton','String','Rotate', ...
    'Units','normalized','Position',[0.81 0.58 0.052 0.04], ...
    'Callback',@enableRotate);

uicontrol(fig,'Style','pushbutton','String','Zoom', ...
    'Units','normalized','Position',[0.866 0.58 0.052 0.04], ...
    'Callback',@enableZoom);

uicontrol(fig,'Style','pushbutton','String','Pan', ...
    'Units','normalized','Position',[0.922 0.58 0.052 0.04], ...
    'Callback',@enablePan);

st.axesCheck = uicontrol(fig,'Style','checkbox','String','Show axes', ...
    'Value',0,'Units','normalized','Position',[0.81 0.515 0.16 0.035], ...
    'BackgroundColor','w','Callback',@axesToggle);

st.cbCheck = uicontrol(fig,'Style','checkbox','String','Show strain colorbar', ...
    'Value',1,'Units','normalized','Position',[0.81 0.475 0.17 0.035], ...
    'BackgroundColor','w','Callback',@colorbarToggle);

uicontrol(fig,'Style','text','String','Optional export', ...
    'Units','normalized','Position',[0.81 0.395 0.17 0.035], ...
    'BackgroundColor','w','HorizontalAlignment','left','FontWeight','bold');

uicontrol(fig,'Style','pushbutton','String','Export current PNG', ...
    'Units','normalized','Position',[0.81 0.345 0.17 0.045], ...
    'Callback',@exportPNG);

uicontrol(fig,'Style','pushbutton','String','Export selected MP4', ...
    'Units','normalized','Position',[0.81 0.29 0.17 0.045], ...
    'Callback',@exportVideo);

st.infoText = uicontrol(fig,'Style','text', ...
    'String','Use Rotate, Zoom, Pan, or the MATLAB figure toolbar for interactive inspection.', ...
    'Units','normalized','Position',[0.81 0.14 0.17 0.11], ...
    'BackgroundColor','w','HorizontalAlignment','left');

guidata(fig,st);
renderViewer(fig);
rotate3d(fig,'on');

%% CALLBACKS
function modeChanged(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    names = get(src,'String');
    st.mode = names{get(src,'Value')};
    guidata(fig,st);
    renderViewer(fig);
end

function sliderChanged(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    st.frameIdx = round(get(src,'Value'));
    set(src,'Value',st.frameIdx);
    guidata(fig,st);
    renderViewer(fig);
end

function previousFrame(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    st.frameIdx = max(1,st.frameIdx-1);
    set(st.frameSlider,'Value',st.frameIdx);
    guidata(fig,st);
    renderViewer(fig);
end

function nextFrame(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    st.frameIdx = min(st.nFrames,st.frameIdx+1);
    set(st.frameSlider,'Value',st.frameIdx);
    guidata(fig,st);
    renderViewer(fig);
end

function topView(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    view(st.ax,[0 90]);
end

function obliqueView(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    view(st.ax,[st.obliqueAz st.obliqueEl]);
end

function enableRotate(src,~)
    fig = ancestor(src,'figure');
    zoom(fig,'off'); pan(fig,'off'); rotate3d(fig,'on');
end

function enableZoom(src,~)
    fig = ancestor(src,'figure');
    rotate3d(fig,'off'); pan(fig,'off'); zoom(fig,'on');
end

function enablePan(src,~)
    fig = ancestor(src,'figure');
    rotate3d(fig,'off'); zoom(fig,'off'); pan(fig,'on');
end

function axesToggle(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    st.showAxes = logical(get(src,'Value'));
    guidata(fig,st);
    renderViewer(fig);
end

function colorbarToggle(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);
    st.showColorbar = logical(get(src,'Value'));
    guidata(fig,st);
    renderViewer(fig);
end

function exportPNG(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);

    if ~exist(st.resultsRoot,'dir'), mkdir(st.resultsRoot); end
    outDir = fullfile(st.resultsRoot,'exported_images');
    if ~exist(outDir,'dir'), mkdir(outDir); end

    [az,el] = view(st.ax);
    outFile = fullfile(outDir, ...
        sprintf('%s_frame_%03d.png',sanitizeName(st.mode),st.frameIdx));

    exportSingleFrame(st,st.frameIdx,st.mode,az,el,outFile);
    set(st.infoText,'String',sprintf('Saved:\n%s',outFile));
end

function exportVideo(src,~)
    fig = ancestor(src,'figure');
    st = guidata(fig);

    if ~exist(st.resultsRoot,'dir'), mkdir(st.resultsRoot); end
    outDir = fullfile(st.resultsRoot,'exported_videos');
    if ~exist(outDir,'dir'), mkdir(outDir); end

    outFile = fullfile(outDir,[sanitizeName(st.mode) '.mp4']);
    [az,el] = view(st.ax);

    writer = VideoWriter(outFile,'MPEG-4');
    writer.FrameRate = st.videoFPS;
    open(writer);

    tmpFig = figure('Color','w','Visible','off','Position',[100 100 800 800]);
    tmpAx = axes('Parent',tmpFig,'Position',[0.08 0.08 0.82 0.84]);

    h = waitbar(0,sprintf('Exporting %s...',st.mode));

    try
        for k = 1:st.nFrames
            renderModeOnAxes(tmpAx,st,k,st.mode,az,el,true);
            drawnow;
            writeVideo(writer,getframe(tmpFig));
            if ishandle(h), waitbar(k/st.nFrames,h); end
        end
        close(writer);
        close(tmpFig);
        if ishandle(h), close(h); end
        set(st.infoText,'String',sprintf('Saved:\n%s',outFile));
    catch ME
        try, close(writer); end %#ok<TRYNC>
        if ishandle(tmpFig), close(tmpFig); end
        if ishandle(h), close(h); end
        rethrow(ME);
    end
end

%% RENDER
function renderViewer(fig)
    st = guidata(fig);

    if st.hasRendered
        [az,el] = view(st.ax);
    else
        az = st.obliqueAz;
        el = st.obliqueEl;
    end

    renderModeOnAxes(st.ax,st,st.frameIdx,st.mode,az,el,false);

    set(st.frameText,'String',sprintf('Frame %d / %d',st.frameIdx,st.nFrames));
    set(st.frameSlider,'Value',st.frameIdx);

    st.hasRendered = true;
    guidata(fig,st);
end

function renderModeOnAxes(ax,st,frameIdx,modeName,az,el,isExport)
    cla(ax,'reset');
    [P,RGB_ML,eeq_pct] = frameData(st,frameIdx);

    hold(ax,'on');

    switch modeName
        case 'Point cloud'
            plot3(ax,P(:,1),P(:,2),P(:,3),'.', ...
                'Color',[0 0.4470 0.7410],'MarkerSize',8);

        case 'Triangular mesh'
            patch('Parent',ax,'Faces',st.Fplot,'Vertices',P, ...
                'FaceColor','none','EdgeColor','k', ...
                'LineWidth',0.8,'FaceLighting','none');

        case 'Reconstructed 3D ML'
            patch('Parent',ax,'Faces',st.Fplot,'Vertices',P, ...
                'FaceVertexCData',RGB_ML,'FaceColor','interp', ...
                'EdgeColor','none','FaceLighting','none');

        case 'Effective strain'
            patch('Parent',ax,'Faces',st.Fplot,'Vertices',P, ...
                'FaceVertexCData',eeq_pct,'FaceColor','flat', ...
                'EdgeColor','none','FaceLighting','none');
            colormap(ax,turbo);
            caxis(ax,st.strainLimits);

            if st.showColorbar
                cb = colorbar(ax,'eastoutside');
                cb.Label.String = 'Effective strain (%)';
            end
    end

    hold(ax,'off');
    axis(ax,'equal');
    axis(ax,st.globalAxis);
    view(ax,[az el]);

    if st.flipY, set(ax,'YDir','reverse'); end
    if st.flipX, set(ax,'XDir','reverse'); end
    if st.useOrtho, camproj(ax,'orthographic'); end

    lighting(ax,'none');
    grid(ax,'off');

    if st.showAxes
        axis(ax,'on');
        box(ax,'on');
        xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z');
    else
        axis(ax,'off');
        box(ax,'off');
    end

    if ~isExport
        title(ax,sprintf('%s | Frame %d',modeName,frameIdx), ...
            'Interpreter','none','FontWeight','normal');
    end
end

function [P,RGB_ML,eeq_pct] = frameData(st,frameIdx)
    P = st.D.Points3D_ARBM{frameIdx};
    P(:,3) = -P(:,3);

    pts2D = st.D.DIC2Dinfo.Points{frameIdx};
    xv = round(pts2D(:,1));
    yv = round(pts2D(:,2));

    ML = im2double(imread(fullfile(st.mlFolder,st.mlFiles(frameIdx).name)));

    if ndims(ML) == 2
        ML = repmat(ML,[1 1 3]);
    elseif size(ML,3) > 3
        ML = ML(:,:,1:3);
    end

    [hML,wML,~] = size(ML);
    RGB_ML = zeros(size(P,1),3);

    nMap = min([size(P,1),numel(xv),numel(yv)]);
    valid = false(size(P,1),1);
    valid(1:nMap) = xv(1:nMap)>=1 & xv(1:nMap)<=wML & ...
                    yv(1:nMap)>=1 & yv(1:nMap)<=hML;

    for k = find(valid)'
        RGB_ML(k,:) = reshape(ML(yv(k),xv(k),:),1,3);
    end

    eeq = st.D.Deform.Eeq{frameIdx};
    eeq = eeq(st.validFaces);
    eeq(~isfinite(eeq)) = 0;
    eeq_pct = eeq*100;
end

%% EXPORT CURRENT FRAME
function exportSingleFrame(st,frameIdx,modeName,az,el,outFile)
    f = figure('Color','w','Visible','off','Position',[100 100 800 800]);
    a = axes('Parent',f,'Position',[0.08 0.08 0.82 0.84]);
    renderModeOnAxes(a,st,frameIdx,modeName,az,el,true);
    set(f,'InvertHardcopy','off');
    print(f,outFile,'-dpng',sprintf('-r%d',st.exportDPI));
    close(f);
end

%% HELPERS
function filesOut = sortFilesNumeric(filesIn)
    names = {filesIn.name};
    nums = zeros(numel(names),1);

    for i = 1:numel(names)
        tok = regexp(names{i},'\d+','match');
        if isempty(tok)
            nums(i) = i;
        else
            nums(i) = str2double(tok{end});
        end
    end

    [~,idx] = sort(nums);
    filesOut = filesIn(idx);
end

function s = sanitizeName(s0)
    s = regexprep(s0,'[^a-zA-Z0-9_\-]','_');
end
