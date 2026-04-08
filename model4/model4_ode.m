function dydt = model4_ode(time, y, p, c)
InsR = y(1);
pInsR = y(2);
IRS = y(3);
pIRS = y(4);
otud = y(5);
aotud = y(6);
GBL = y(7);
GBLubi = y(8);
Raptor = y(9);
Sin1 = y(10);
mTORC2 = y(11);
pmTORC2 = y(12);
mTORC1 = y(13);
pmTORC1 = y(14);
Akt = y(15);
pAkt473 = y(16);
pAkt308 = y(17);
pAkt308473 = y(18);
s6k1 = y(19);
ps6k1 = y(20);
TSC2 = y(21);
pTSC2 = y(22);

if time >= c.Timeinput1 && time < (c.Timeinput1 + c.Tinfinput1)
    Ins = p.Ins0;
else
    Ins = 0;
end

v1 = p.kf1 * InsR * (Ins + p.InsB0) / ((p.km1 + InsR) * (1 + p.ki1 * pmTORC1)) ...
    - p.kr1 * pInsR;
v2 = p.kf2 * IRS * pInsR / ((p.km2 + IRS) * (1 + p.ki2 * ps6k1)) ...
    - p.kr2 * pIRS;
v3 = p.kf3 * pIRS * otud / (p.km3 + otud) - p.kr3 * aotud;
v4 = p.kf4 * aotud * GBLubi / (p.km4 + GBLubi) - p.kr4 * GBL * p.traf;
v5 = p.kf5 * GBLubi * Raptor - p.kr5 * mTORC1;
v6 = p.kf6 * Sin1 * GBL - p.kr6 * mTORC2;
v7 = p.kf7 * pIRS * Akt / (p.km7 + Akt) - p.kr7 * pAkt308;
v8 = p.kf8 * pmTORC2 * Akt / (p.km8 + Akt) - p.kr8 * pAkt473;
v9 = p.kf7 * pIRS * pAkt473 / (p.km9 + pAkt473) - p.kr7 * pAkt308473;
v10 = p.kf8 * pmTORC2 * pAkt308 / (p.km10 + pAkt308) - p.kr8 * pAkt308473;
v11 = (p.kf11a * pAkt308 + p.kf11b * pAkt308473) * mTORC2 / (p.km11 + mTORC2) ...
    - p.kr11 * pmTORC2;
v12 = TSC2 * (p.kf12a * pAkt308 + p.kf12b * pAkt308473) / (p.km12 + TSC2) ...
    - p.kr12 * pTSC2;
v13 = p.kf13 * mTORC1 / (1 + p.ki13 * TSC2) - p.kr13 * pmTORC1;
v14 = p.kf14 * pmTORC1 * (s6k1 / (p.km14 + s6k1)) - p.kr14 * ps6k1;

dydt = zeros(22, 1);
dydt(1) = -v1;
dydt(2) = v1;
dydt(3) = -v2;
dydt(4) = v2;
dydt(5) = -v3;
dydt(6) = v3;
dydt(7) = v4 - v6;
dydt(8) = -v4 - v5;
dydt(9) = -v5;
dydt(10) = -v6;
dydt(11) = v6 - v11;
dydt(12) = v11;
dydt(13) = v5 - v13;
dydt(14) = v13;
dydt(15) = -v7 - v8;
dydt(16) = v8 - v9;
dydt(17) = v7 - v10;
dydt(18) = v9 + v10;
dydt(19) = -v14;
dydt(20) = v14;
dydt(21) = -v12;
dydt(22) = v12;
end
