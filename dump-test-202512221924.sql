-- MySQL dump 10.13  Distrib 8.0.40, for macos15.2 (arm64)
--
-- Host: db-mysql-blr1-72411-do-user-27086038-0.f.db.ondigitalocean.com    Database: test
-- ------------------------------------------------------
-- Server version	8.0.35

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '138a9b2d-de60-11f0-8506-92700261a531:1-193';

--
-- Table structure for table `match`
--

DROP TABLE IF EXISTS `match`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `match` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_name` varchar(50) NOT NULL,
  `team1_id` varchar(50) DEFAULT NULL,
  `team2_id` varchar(50) DEFAULT NULL,
  `round_id` varchar(50) NOT NULL,
  `pool` varchar(50) NOT NULL,
  `winner_team_id` varchar(50) DEFAULT NULL,
  `is_final` tinyint(1) DEFAULT NULL,
  `tournament_id` int NOT NULL,
  `court_number` int DEFAULT NULL,
  `court_order` int DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `outcome_type` varchar(20) NOT NULL DEFAULT 'normal',
  `predecessor_1` int DEFAULT NULL,
  `predecessor_2` int DEFAULT NULL,
  `successor` int DEFAULT NULL,
  `bracket_position` int DEFAULT NULL,
  `round_number` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `team1_id` (`team1_id`),
  KEY `team2_id` (`team2_id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `predecessor_1` (`predecessor_1`),
  KEY `predecessor_2` (`predecessor_2`),
  KEY `successor` (`successor`),
  CONSTRAINT `match_ibfk_1` FOREIGN KEY (`team1_id`) REFERENCES `team` (`team_id`),
  CONSTRAINT `match_ibfk_2` FOREIGN KEY (`team2_id`) REFERENCES `team` (`team_id`),
  CONSTRAINT `match_ibfk_3` FOREIGN KEY (`tournament_id`) REFERENCES `tournament` (`id`),
  CONSTRAINT `match_ibfk_4` FOREIGN KEY (`predecessor_1`) REFERENCES `match` (`id`),
  CONSTRAINT `match_ibfk_5` FOREIGN KEY (`predecessor_2`) REFERENCES `match` (`id`),
  CONSTRAINT `match_ibfk_6` FOREIGN KEY (`successor`) REFERENCES `match` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `match`
--

LOCK TABLES `match` WRITE;
/*!40000 ALTER TABLE `match` DISABLE KEYS */;
INSERT INTO `match` (`id`,`match_name`,`team1_id`,`team2_id`,`round_id`,`pool`,`winner_team_id`,`is_final`,`tournament_id`,`court_number`,`court_order`,`status`,`predecessor_1`,`predecessor_2`,`successor`,`bracket_position`,`round_number`) VALUES (7,'Round 1 Pool A - Thunder Smash vs Lightning Serve','T001','T002','1','A',NULL,0,1,NULL,NULL,'pending',NULL,NULL,NULL,NULL,NULL),(8,'Round 1 Pool A - Thunder Smash vs Smashers','T001','T003','1','A',NULL,0,1,NULL,NULL,'pending',NULL,NULL,NULL,NULL,NULL),(9,'Round 1 Pool A - Thunder Smash vs Destroyers','T001','T004','1','A',NULL,0,1,NULL,NULL,'pending',NULL,NULL,NULL,NULL,NULL),(10,'Round 1 Pool A - Lightning Serve vs Smashers','T002','T003','1','A',NULL,0,1,NULL,NULL,'pending',NULL,NULL,NULL,NULL,NULL),(11,'Round 1 Pool A - Lightning Serve vs Destroyers','T002','T004','1','A',NULL,0,1,NULL,NULL,'pending',NULL,NULL,NULL,NULL,NULL),(12,'Round 1 Pool A - Smashers vs Destroyers','T003','T004','1','A',NULL,0,1,NULL,NULL,'pending',NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `match` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player`
--

DROP TABLE IF EXISTS `player`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `player` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` varchar(36) DEFAULT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `gender` varchar(10) NOT NULL,
  `age` int NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `email` varchar(120) NOT NULL,
  `skill_type` varchar(20) NOT NULL,
  `dupr_id` varchar(50) DEFAULT NULL,
  `super_tournament_id` int NOT NULL,
  `checked_in` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `super_tournament_id` (`super_tournament_id`),
  KEY `ix_player_phone_number` (`phone_number`),
  CONSTRAINT `player_ibfk_1` FOREIGN KEY (`super_tournament_id`) REFERENCES `super_tournament` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player`
--

LOCK TABLES `player` WRITE;
/*!40000 ALTER TABLE `player` DISABLE KEYS */;
INSERT INTO `player` VALUES (1,'7SAPH','John','Smith','Male',28,'1234567890','john.smith@email.com','INTERMEDIATE','DUPR123',1,0),(2,'S0GY3','Sarah','Johnson','Female',25,'2345678901','sarah.j@email.com','ADVANCED','DUPR124',1,0),(3,'TKUSU','Mike','Wilson','',0,'2345678903','','','',1,0),(4,'PMC0M','Emma','Davis','',0,'2345678904','','','',1,0),(5,'2N77P','David','Brown','',0,'2345678905','','','',1,0),(6,'J6ML3','Lisa','Anderson','',0,'2345678906','','','',1,0),(7,'EN5UQ','James','Lee','',0,'2345678907','','','',1,0),(8,'VK5AD','Rachel','White','',0,'2345678908','','','',1,0);
/*!40000 ALTER TABLE `player` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `round`
--

DROP TABLE IF EXISTS `round`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `round` (
  `id` int NOT NULL AUTO_INCREMENT,
  `round_id` int NOT NULL,
  `team_id` varchar(50) DEFAULT NULL,
  `pool` varchar(20) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `tournament_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `team_id` (`team_id`),
  KEY `tournament_id` (`tournament_id`),
  CONSTRAINT `round_ibfk_1` FOREIGN KEY (`team_id`) REFERENCES `team` (`team_id`),
  CONSTRAINT `round_ibfk_2` FOREIGN KEY (`tournament_id`) REFERENCES `tournament` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `round`
--

LOCK TABLES `round` WRITE;
/*!40000 ALTER TABLE `round` DISABLE KEYS */;
INSERT INTO `round` VALUES (5,1,'T001','A','Round Robin',1),(6,1,'T002','A','Round Robin',1),(7,1,'T003','A','Round Robin',1),(8,1,'T004','A','Round Robin',1);
/*!40000 ALTER TABLE `round` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `score`
--

DROP TABLE IF EXISTS `score`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `score` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `team_id` varchar(50) NOT NULL,
  `score` int NOT NULL,
  `points` int DEFAULT NULL,
  `tournament_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `match_id` (`match_id`),
  KEY `team_id` (`team_id`),
  KEY `tournament_id` (`tournament_id`),
  CONSTRAINT `score_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `match` (`id`),
  CONSTRAINT `score_ibfk_2` FOREIGN KEY (`team_id`) REFERENCES `team` (`team_id`),
  CONSTRAINT `score_ibfk_3` FOREIGN KEY (`tournament_id`) REFERENCES `tournament` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `score`
--

LOCK TABLES `score` WRITE;
/*!40000 ALTER TABLE `score` DISABLE KEYS */;
INSERT INTO `score` VALUES (1,7,'T001',0,0,1),(2,7,'T002',0,0,1),(3,8,'T001',0,0,1),(4,8,'T003',0,0,1),(5,9,'T001',0,0,1),(6,9,'T004',0,0,1),(7,10,'T002',0,0,1),(8,10,'T003',0,0,1),(9,11,'T002',0,0,1),(10,11,'T004',0,0,1),(11,12,'T003',0,0,1),(12,12,'T004',0,0,1);
/*!40000 ALTER TABLE `score` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `season`
--

DROP TABLE IF EXISTS `season`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `season` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `super_tournament_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `super_tournament_id` (`super_tournament_id`),
  CONSTRAINT `season_ibfk_1` FOREIGN KEY (`super_tournament_id`) REFERENCES `super_tournament` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `season`
--

LOCK TABLES `season` WRITE;
/*!40000 ALTER TABLE `season` DISABLE KEYS */;
INSERT INTO `season` VALUES (1,'S1',1);
/*!40000 ALTER TABLE `season` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `super_tournament`
--

DROP TABLE IF EXISTS `super_tournament`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `super_tournament` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `super_tournament`
--

LOCK TABLES `super_tournament` WRITE;
/*!40000 ALTER TABLE `super_tournament` DISABLE KEYS */;
INSERT INTO `super_tournament` VALUES (1,'Assignment','assignment');
/*!40000 ALTER TABLE `super_tournament` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `team`
--

DROP TABLE IF EXISTS `team`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `team` (
  `team_id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `points` int DEFAULT NULL,
  `checked_in` tinyint(1) DEFAULT NULL,
  `tournament_id` int NOT NULL,
  `player1_uuid` varchar(36) DEFAULT NULL,
  `player2_uuid` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`team_id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `player1_uuid` (`player1_uuid`),
  KEY `player2_uuid` (`player2_uuid`),
  CONSTRAINT `team_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournament` (`id`),
  CONSTRAINT `team_ibfk_2` FOREIGN KEY (`player1_uuid`) REFERENCES `player` (`uuid`),
  CONSTRAINT `team_ibfk_3` FOREIGN KEY (`player2_uuid`) REFERENCES `player` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `team`
--

LOCK TABLES `team` WRITE;
/*!40000 ALTER TABLE `team` DISABLE KEYS */;
INSERT INTO `team` VALUES ('T001','Thunder Smash',0,0,1,'7SAPH','S0GY3'),('T002','Lightning Serve',0,0,1,'TKUSU','PMC0M'),('T003','Smashers',0,0,1,'2N77P','J6ML3'),('T004','Destroyers',0,0,1,'EN5UQ','VK5AD');
/*!40000 ALTER TABLE `team` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tournament`
--

DROP TABLE IF EXISTS `tournament`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tournament` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_name` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `num_courts` int DEFAULT NULL,
  `season_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `season_id` (`season_id`),
  CONSTRAINT `tournament_ibfk_1` FOREIGN KEY (`season_id`) REFERENCES `season` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tournament`
--

LOCK TABLES `tournament` WRITE;
/*!40000 ALTER TABLE `tournament` DISABLE KEYS */;
INSERT INTO `tournament` VALUES (1,'Men\'s Singles~Delhi~singles','elimination',1,1);
/*!40000 ALTER TABLE `tournament` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'test'
--
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-22 19:24:16
