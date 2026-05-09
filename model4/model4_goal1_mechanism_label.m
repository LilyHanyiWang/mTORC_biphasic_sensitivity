function mechanismLabel = model4_goal1_mechanism_label(inputName)
if numel(inputName) >= 6 && strcmp(inputName(1:6), 'param:')
    token = inputName(7:end);
else
    token = inputName;
end

if any(strcmp(token, {'kf4', 'km4', 'kr4', 'traf', 'GBL', 'GBLubi', 'otud', 'aotud'}))
    mechanismLabel = 'mLST8 ubiquitination / deubiquitination';
elseif any(strcmp(token, {'kf5', 'kr5', 'Raptor', 'mTORC1', 'pmTORC1'}))
    mechanismLabel = 'Raptor-dependent mTORC1 assembly / activation';
elseif any(strcmp(token, {'kf6', 'kr6', 'Sin1', 'mTORC2', 'pmTORC2'}))
    mechanismLabel = 'SIN1-dependent mTORC2 assembly';
elseif any(strcmp(token, {'kf7', 'km7', 'kr7', 'kf8', 'km8', 'kr8', 'km9', 'km10', ...
        'kf11a', 'kf11b', 'km11', 'kr11', 'Akt', 'pAkt473', 'pAkt308', 'pAkt308473'}))
    mechanismLabel = 'Akt phosphorylation / mTORC2 feedback';
elseif any(strcmp(token, {'kf12a', 'kf12b', 'km12', 'kr12', 'TSC2', 'pTSC2', 'kf13', 'ki13', 'kr13'}))
    mechanismLabel = 'TSC2-mediated control of mTORC1';
elseif any(strcmp(token, {'kf1', 'km1', 'kr1', 'ki1', 'InsB0', 'Ins0', 'InsR', 'pInsR', ...
        'kf2', 'km2', 'ki2', 'kr2', 'IRS', 'pIRS', 'kf3', 'km3', 'kr3', ...
        'kf14', 'km14', 'kr14', 's6k1', 'ps6k1'}))
    mechanismLabel = 'Upstream insulin / IRS / S6K1 feedback';
else
    mechanismLabel = 'Other / mixed mechanism';
end
end
