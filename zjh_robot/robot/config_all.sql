
DELETE FROM `config_mgzjh_robot` WHERE 1=1;
INSERT INTO `config_mgzjh_robot` (`userid`, `username`, `pwd`, `nick`, `phone`, `imei`, `imsi`, `email`, `addr`, `avatar`, `gender`, `balance`, `state`, `channel`, `subChannel`) 
VALUES 
(1,'mgzjh1001','a123123','我来自火星01','12345678901','imei00001','imsi00001','a@b.com01','西溪银泰01','av124',1,1000,0,'ch001','sch001'),
(2,'mgzjh1002','a123123','我来自火星02','12345678902','imei00002','imsi00002','a@b.com02','西溪银泰02','av124',1,1000,0,'ch002','sch002'),
(3,'mgzjh1003','a123123','我来自火星03','12345678903','imei00003','imsi00003','a@b.com03','西溪银泰03','av124',1,1000,0,'ch003','sch003'),
(4,'mgzjh1004','a123123','我来自火星04','12345678904','imei00004','imsi00004','a@b.com04','西溪银泰04','av124',1,1000,0,'ch004','sch004'),
(5,'mgzjh1005','a123123','我来自火星05','12345678905','imei00005','imsi00005','a@b.com05','西溪银泰05','av124',1,1000,0,'ch005','sch005'),
(6,'mgzjh1006','a123123','我来自火星06','12345678906','imei00006','imsi00006','a@b.com06','西溪银泰06','av124',1,1000,0,'ch006','sch006'),
(7,'mgzjh1007','a123123','我来自火星07','12345678907','imei00007','imsi00007','a@b.com07','西溪银泰07','av124',1,1000,0,'ch007','sch007'),
(8,'mgzjh1008','a123123','我来自火星08','12345678908','imei00008','imsi00008','a@b.com08','西溪银泰08','av124',1,1000,0,'ch008','sch008'),
(9,'mgzjh1009','a123123','我来自火星09','12345678909','imei00009','imsi00009','a@b.com09','西溪银泰09','av124',1,1000,0,'ch009','sch009'),
(10,'mgzjh1010','a123123','我来自火星10','12345678910','imei00010','imsi00010','a@b.com10','西溪银泰10','av124',1,1000,0,'ch010','sch010'),
(11,'mgzjh1011','a123123','我来自火星11','12345678911','imei00011','imsi00011','a@b.com11','西溪银泰11','av124',1,1000,0,'ch011','sch011'),
(12,'mgzjh1012','a123123','我来自火星12','12345678912','imei00012','imsi00012','a@b.com12','西溪银泰12','av124',1,1000,0,'ch012','sch012'),
(13,'mgzjh1013','a123123','我来自火星13','12345678913','imei00013','imsi00013','a@b.com13','西溪银泰13','av124',1,1000,0,'ch013','sch013'),
(14,'mgzjh1014','a123123','我来自火星14','12345678914','imei00014','imsi00014','a@b.com14','西溪银泰14','av124',1,1000,0,'ch014','sch014'),
(15,'mgzjh1015','a123123','我来自火星15','12345678915','imei00015','imsi00015','a@b.com15','西溪银泰15','av124',1,1000,0,'ch015','sch015'),
(16,'mgzjh1016','a123123','我来自火星16','12345678916','imei00016','imsi00016','a@b.com16','西溪银泰16','av124',1,1000,0,'ch016','sch016'),
(17,'mgzjh1017','a123123','我来自火星17','12345678917','imei00017','imsi00017','a@b.com17','西溪银泰17','av124',1,1000,0,'ch017','sch017'),
(18,'mgzjh1018','a123123','我来自火星18','12345678918','imei00018','imsi00018','a@b.com18','西溪银泰18','av124',1,1000,0,'ch018','sch018'),
(19,'mgzjh1019','a123123','我来自火星19','12345678919','imei00019','imsi00019','a@b.com19','西溪银泰19','av124',1,1000,0,'ch019','sch019'),
(20,'mgzjh1020','a123123','我来自火星20','12345678920','imei00020','imsi00020','a@b.com20','西溪银泰20','av124',1,1000,0,'ch020','sch020')
ON DUPLICATE KEY UPDATE `username` = VALUES(`username`), `pwd` = VALUES(`pwd`), `nick` = VALUES(`nick`), `phone` = VALUES(`phone`), `imei` = VALUES(`imei`), `imsi` = VALUES(`imsi`), `email` = VALUES(`email`), `addr` = VALUES(`addr`), `avatar` = VALUES(`avatar`), `gender` = VALUES(`gender`), `balance` = VALUES(`balance`), `state` = VALUES(`state`), `channel` = VALUES(`channel`), `subChannel` = VALUES(`subChannel`);
