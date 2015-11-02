/*
Navicat MySQL Data Transfer

Source Server         : 172.16.10.87
Source Server Version : 50527
Source Host           : 172.16.10.87:3306
Source Database       : card

Target Server Type    : MYSQL
Target Server Version : 50527
File Encoding         : 65001

Date: 2014-01-06 14:15:57
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `card`
-- ----------------------------
DROP TABLE IF EXISTS `card`;
CREATE TABLE `card` (
  `card_id` char(32) CHARACTER SET utf8 NOT NULL,
  `type` smallint(6) NOT NULL,
  `server` varchar(256) CHARACTER SET utf8 DEFAULT NULL,
  `dbid` bigint(20) DEFAULT NULL,
  `create_item_id` bigint(20) NOT NULL,
  `create_time` int(11) DEFAULT NULL,
  PRIMARY KEY (`card_id`),
  KEY `index_server` (`server`(255)),
  KEY `index_dbid` (`dbid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;