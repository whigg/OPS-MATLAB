% =========================================================================
% OPS TEST UTILITY
%
% Tests all of the OPS functions on a fresh database using mock data.
%
% No user input is required.
%
% WARNING: THIS SHOULD BE DONE ON AND EMPTY DEVELOPMENT DATABASE ONLY.
%
% LEAVE THE CREATE USER AND LOGIN PROMPTS AS DEFAULTS
%
% Author: Kyle W. Purdon
%
% =========================================================================

%% USER OVERWRITE
deleteAfterCompleteion = true;

%% warning CHECK BEFORE STARTING
opsCmd;
if strcmp(gOps.serverUrl,{'https://ops.cresis.ku.edu/ops/','http://ops2.cresis.ku.edu/ops/'})
  warning('warning: DO NOT USE THIS FUNCTION ON THE PRODUCTION DATABASE');
end

%% CREATE A NEW USER
clear param;
[status,newUser] = opsCreateUser();
if status ~= 1
  warning(newUser);
end

%% AUTHENTICATE THE NEW USER
param = struct('properties',[]);
[~,opsAuth,opsProfile] = opsAuthenticate(param);

% %% LOGIN THE NEW USER
% clear param;
% [status,loginNotice] = opsLoginUser();
% if status == 1
%   opsAuth = load(fullfile(gRadar.tmp_path,'ops.mat'));
% elseif status ~= 1
%   warning(loginNotice);
% end
% 
% %% GET THE NEW USERS PROFILE (NOW HANDLED IN opsLoginUser)
% opsProfile = load(fullfile(gRadar.tmp_path,'ops.profile.mat'));
% % clear param;
% % [status,profile_notice] = opsGetUserProfileData();
% % if status == 1
% %   opsProfile = load(fullfile(gRadar.tmp_path,'ops.profile.mat'));
% % elseif status ~= 1
% %   warning(profile_notice);
% % end

%% CREATE NEW LAYER GROUP
clear param;
param.properties.lyr_name = 'test';
param.properties.lyr_group_name = 'standard';
param.properties.lyr_description = 'this is a test layer';
[status,newLayer] = opsCreateLayer('rds',param);
if status ~= 1
  warning(newLayer);
end

%% CREATE NEW LAYER (NOT IN USER DEFAULT ALLOCATED GROUP)
clear param;
param.properties.lyr_name = 'test1';
param.properties.lyr_group_name = 'testLayerGroup';
param.properties.lyr_description = 'this is a test layer 1';
[status,newLayer2] = opsCreateLayer('rds',param);
if status ~= 1
  warning(newLayer2);
end

%% DELETE LAYER
clear param;
param.properties.lyr_name = 'test';
[~,deletedLayer] = opsDeleteLayer('rds',param);
if status ~= 1
  warning(deletedLayer);
end
if ~(deletedLayer.properties.lyr_id == newLayer.properties.lyr_id)
  warning('layer deletion failed to delete the correct layer');
end

%% RELEASE LAYER GROUP (NEED TO ADD AUTH PERMISSIONS!)
% clear param;
% param.properties.lyr_group_name = '';
% [status,pubGroup] = opsReleaseLayerGroup('rds',param);
% if status ~= 1
%   warning(pubGroup);
% end

%% GET LAYERS
[status,allLayers] = opsGetLayers('rds');
if status ~= 1
  warning(allLayers);
end
if any(newLayer.properties.lyr_id == allLayers.properties.lyr_id)
  warning('layer was not deleted');
end

%% RECREATE DELETED LAYER
clear param;
param.properties.lyr_name = 'test';
param.properties.lyr_group_name = 'standard';
param.properties.lyr_description = 'this is a test layer';
[status,newLayer] = opsCreateLayer('rds',param);
if status ~= 1
  warning(newLayer);
end

%% GET LAYERS (TO CONFIRM LAYER WAS RECREATED)
[status,allLayers] = opsGetLayers('rds');
if status ~= 1
  warning(allLayers);
end
if ~any(newLayer.properties.lyr_id == allLayers.properties.lyr_id)
  warning('layer was not recreated');
end

%% QUERY (INSERT A TEST SEASON [CRESIS_PRIVATE])
[status,qData] = opsQuery('INSERT INTO rds_seasons (location_id,name,season_group_id) VALUES (1,''test1'',2) returning id;');
if status ~= 1
  warning(qData);
end
seasonId = double(qData{1});

%% QUERY (INSERT A TEST SEASON [CRESIS_PUBLIC])
[status,qData] = opsQuery('INSERT INTO rds_seasons (location_id,name,season_group_id) VALUES (1,''test'',1) returning id;');
if status ~= 1
  warning(qData);
end
seasonId = double(qData{1});

%% RELEASE SEASON ( NOT IN AUTH, NO PUBLIC)
% clear param;
% param.properties.season_name = '';
% [status,pubSeason] = opsReleaseSeason('rds',param);
% if status ~= 1
%   warning(pubSeason);
% end

%% GET SYSTEM INFO (MAKE SURE ONLY SEASON TEST1 SHOWS UP)
[status,getSysData] = opsGetSystemInfo();
if status == 1
  if ~all(size(getSysData.properties.seasons) == [1 1])
    warning('non-authorized seasons returned');
  end
else
  warning(getSysData);
end

%% CREATE PATH (FAKE DATA)
clear param;
param.geometry.coordinates = [[76.422813519870743;76.422813519870743;76.422813519870743] [-68.994377212760924; -68.994377212760924; -68.994377212760924]];
param.properties.location = 'arctic';
param.properties.season = 'test';
param.properties.radar = 'test';
param.properties.segment = '99999999_01';
param.properties.gps_time = [1301569765.964949,1301569766.964949,1301569767.964949,1301569768.964949];
param.properties.elev = [1257.839261098396,1258.839261098396,1259.839261098396,1260.839261098396];
param.properties.roll = [-0.249471361002334,-0.249471361002334,-0.249471361002334,-0.249471361002334];
param.properties.pitch = [0.088953745496139,0.088953745496139,0.088953745496139,0.088953745496139];
param.properties.heading = [2.147027618159285,2.147027618159285,2.147027618159285,2.147027618159285];
param.properties.frame_count = 2;
param.properties.frame_start_gps_time = [1301569765.964949,1301569767.964949];
[status,pathStatus] = opsCreatePath('rds',param);
if status ~= 1
  warning(pathStatus);
end

%% GET PATH
clear param;
param.properties.location = 'arctic';
param.properties.season = 'test';
param.properties.start_gps_time = 1301569765.964949;
param.properties.stop_gps_time = 1301569768.964949;
param.properties.nativeGeom = true;
[status,pathData] = opsGetPath('rds',param);
if status ~= 1
  warning(pathData);
end

%% CREATE LAYER POINTS
clear param;
param.properties.point_path_id = pathData.properties.id;
param.properties.username = 'kpurdon';
param.properties.twtt = [0.00000241705663401991,0.00000251705663401991,0.00000231705663401991];
param.properties.type = [1 2 1];
param.properties.quality = [1 2 3];
param.properties.lyr_name = 'test';
[status,lpData] = opsCreateLayerPoints('rds',param);
if status ~= 1
  warning(lpData);
end

%% CREATE LAYER POINTS (AGAIN, TEST DUPLICATES AND NAN DELETION)
clear param;
param.properties.point_path_id = pathData.properties.id;
param.properties.username = 'kpurdon';
param.properties.twtt = [0.00000241705663401991,0.00000251705663401991,NaN];
param.properties.type = [1 2 1];
param.properties.quality = [1 2 3];
param.properties.lyr_name = 'test';
[status,lpData] = opsCreateLayerPoints('rds',param);
if status ~= 1
  warning(lpData);
end

%% GET LAYER POINTS
clear param;
param.properties.point_path_id = pathData.properties.id;
[status,lpGetData] = opsGetLayerPoints('rds',param);
if status ~= 1
  warning(lpGetData);
else
  if length(lpGetData.properties.gps_time) > 2
    warning('Duplicates were created or NaN did not delete.');
    keyboard;
  end
end


%% DELETE LAYER POINTS
clear param;
param.properties.start_point_path_id = pathData.properties.id(2);
param.properties.stop_point_path_id = pathData.properties.id(2);
param.properties.max_twtt = 0.00000261705663401991;
param.properties.min_twtt = 0.00000242705663401991;
param.properties.lyr_name = 'test';
[status,lpDelData] = opsDeleteLayerPoints('rds',param);
if status ~= 1
  warning(lpDelData);
end

%% GET LAYER POINTS
clear param;
param.properties.point_path_id = pathData.properties.id;
[status,lpGetData] = opsGetLayerPoints('rds',param);
if status ~= 1
  warning(lpGetData);
end

%% GET LAYER POINTS WTIH GEOM
clear param;
param.properties.location = 'arctic';
param.properties.point_path_id = pathData.properties.id;
param.properties.return_geom = 'geog';
[status,lpGetData] = opsGetLayerPoints('rds',param);
if status ~= 1
  warning(lpGetData);
end

%% GET LAYER POINTS WTIH GEOM (PROJECTED)
param.properties.return_geom = 'proj';
[status,lpGetData] = opsGetLayerPoints('rds',param);
if status ~= 1
  warning(lpGetData);
end

%% GET LAYER POINTS CSV/KML
% CANT TEST IN MATLAB RIGHT NOW (NO API FOR KML/CSV GET)...

%% GET FRAME CLOSEST
clear param;
param.properties.location = 'arctic';
param.properties.season = 'test';
param.properties.x = 2924.333796700000;
param.properties.y = 89999.049551300004;
[status,cFrmData] = opsGetFrameClosest('rds',param);
if status ~= 1
  warning(cFrmData);
end

%% GET FRAME SEARCH
clear param;
param.properties.search_str = '999999'; %'99999999_01_001'
param.properties.location = 'arctic';
[status,sFrmData] = opsGetFrameSearch('rds',param);
if status ~= 1
  warning(sFrmData);
end

%% GET SYSTEM INFO
[status,sysData] = opsGetSystemInfo();
if status ~= 1
  warning(sysData);
end

%% GET SEGMENT INFO
clear param;
param.properties.segment_id = sFrmData.properties.segment_id;
[status,segData] = opsGetSegmentInfo('rds',param);
if status ~= 1
  warning(segData);
end

%% ANALYZE TABLES
clear param;
param.properties.tables = {'layer_points','point_paths','segments','frames'};
[status,anData] = opsAnalyze('rds',param);
if status ~= 1
  warning(anData);
end

%% GET INITIAL DATAPACK
clear param;
param.properties.seasons = {'test'};
param.properties.segments = {'99999999_01'};
param.properties.radars = {'test'};
[status,initData] = opsGetInitialData('rds',param);
if status ~= 1
  warning(initData);
end

if deleteAfterCompleteion
  %% BULK DELETE ALL OF IT
  clear param;
  param.properties.season = 'test';
  [status,delData] = opsDeleteBulk('rds',param);
  if status ~= 1
    warning(delData);
  end

  param.properties.season = 'test1';
  [status,delData] = opsDeleteBulk('rds',param);
  if status ~= 1
    warning(delData);
  end
  
  fprintf('NO ERRORS OCCURED. TESTS PASSED\n');
  
  %% CLEANUP (DELETE LAYERS AND LAYER GROUPS)
  [status,cData] = opsQuery('DELETE FROM rds_layers WHERE name=''test'' RETURNING name;');
  [status,cData] = opsQuery('DELETE FROM rds_layers WHERE name=''test1'' RETURNING name;');
  [status,cData] = opsQuery('DELETE FROM rds_layer_groups WHERE name=''testLayerGroup'' RETURNING name;');
end

%% LOGOUT THE NEW USER
clear param;
[status,logoutNotice] = opsLogoutUser();
if status ~= 1
  warning(logoutNotice);
else
  fprintf('%s\n',logoutNotice)
end

%% OTHER TESTS TO DO EVENTUALLY

% PROFILING
% LOAD WITH INITIAL DATA
% CROSSOVERS
% LAYER POINTS CSV/KML/...