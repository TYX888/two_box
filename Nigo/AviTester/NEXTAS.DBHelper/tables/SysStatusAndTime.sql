CREATE DATABASE  IF NOT EXISTS `avidb` /*!40100 DEFAULT CHARACTER SET utf8 */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `avidb`;
-- MySQL dump 10.13  Distrib 8.0.25, for Win64 (x86_64)
--
-- Host: localhost    Database: avidb
-- ------------------------------------------------------
-- Server version	8.0.25

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `sysstatusandtime`
--

DROP TABLE IF EXISTS `sysstatusandtime`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sysstatusandtime` (
  `StatusStartTime` datetime(3) NOT NULL,
  `StatusEndTime` datetime(3) NOT NULL,
  `SysStatus` enum('Idle','Initializing','Ready','Starting','Running','Pausing','Paused','Resuming','Purging','Ending','Abort','Resetting') NOT NULL,
  `SysStatusDuration` bigint unsigned NOT NULL,
  `SysStatusReason` varchar(255) DEFAULT NULL,
  `Id` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sysstatusandtime`
--

LOCK TABLES `sysstatusandtime` WRITE;
/*!40000 ALTER TABLE `sysstatusandtime` DISABLE KEYS */;
INSERT INTO `sysstatusandtime` VALUES ('2021-07-28 07:54:22.446','2021-07-28 07:54:22.446','Idle',10,NULL,1),('2021-07-28 07:54:22.446','2021-07-28 07:54:22.446','Idle',10,NULL,2),('2021-07-28 07:54:22.446','2021-07-28 07:54:22.446','Idle',10,NULL,3),('2021-07-28 07:54:22.446','2021-07-28 07:54:22.446','Idle',10,NULL,4),('2021-07-28 07:54:22.446','2021-07-28 07:54:22.446','Idle',10,NULL,5);
/*!40000 ALTER TABLE `sysstatusandtime` ENABLE KEYS */;
UNLOCK TABLES;
