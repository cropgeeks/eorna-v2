CREATE database eorna2;
USE eorna2;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


-- ----------------------------
-- Table structure for transcript_sequences
-- ----------------------------
DROP TABLE IF EXISTS `transcript_sequences`;
CREATE TABLE `transcript_sequences`  (
  `transcript_id` varchar(30) PRIMARY KEY,
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
DROP TABLE IF EXISTS `transcript_structures`;
CREATE TABLE `transcript_structures`  (
  `transcript_id` varchar(65),
  `dataset_name` varchar(10),
  `f_start` int(8),
  `f_end` int(8),
  `gene_id` varchar(65),
  `chr_id` varchar(5),
  `strand` varchar(1),
  `exon_number` int(4),

INDEX `transcript_dataset`(`transcript_id`, `dataset_name`) USING BTREE
);

-- ----------------------------
-- Table structure for gene_annotation
-- ----------------------------
DROP TABLE IF EXISTS `gene_annotation`;
CREATE TABLE `gene_annotation`  (
  `gene_id` varchar(65),
  `dataset_name` varchar(10),
  `chr_id` varchar(5)L,
  `number_of_transcripts`,
  `gene_start` int(8),
  `gene_end` int(8),
  `strand` varchar(1),
  `pannzer_annotation`,
  `go_ids` text,
  `go_terms` text,
  PRIMARY KEY (`gene_id`) USING BTREE,
  INDEX `transcript_dataset`(`dataset_name`) USING BTREE,
  INDEX `gene_dataset`(`gene_id`, `dataset_name`) USING BTREE,
  INDEX `chr_dataset`(`chr_id`, `dataset_name`) USING BTREE
) ROW_FORMAT = Dynamic;



SET FOREIGN_KEY_CHECKS = 1;
