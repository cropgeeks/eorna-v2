CREATE database eorna2;
USE eorna2;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


-- ----------------------------
-- Table structure for transcript_sequences
-- ----------------------------
DROP TABLE IF EXISTS `transcript_sequences`;
CREATE TABLE `transcript_sequences`  (
  `transcript_id` varchar(25) PRIMARY KEY,
  `gene_id` varchar(20),
  `dataset_name` varchar(10),
  `transcript_sequence` longtext,
  `seq_length` int(7),
  `chr_id` varchar(5),


  INDEX `transcript_dataset`(`transcript_id`, `dataset_name`) USING BTREE,
  INDEX `gene_dataset`(`gene_id`, `dataset_name`) USING BTREE,
  INDEX `chr_dataset`(`chr_id`, `dataset_name`) USING BTREE
);

-- ----------------------------
-- Table structure for transcript_structure
-- ----------------------------
DROP TABLE IF EXISTS `transcript_structure`;
CREATE TABLE `transcript_structure`  (
  `transcript_id` varchar(20),
  `dataset_name` varchar(30),
  `f_start` int(7),
  `f_end` int(7),
  `gene_id` varchar(20),
  `chr_id` varchar(20),
  `strand` varchar(1),
  `exon_number` int(4),

INDEX `transcript_dataset`(`transcript_id`, `dataset_name`) USING BTREE
);



SET FOREIGN_KEY_CHECKS = 1;
