-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Apr 27, 2026 at 02:45 PM
-- Server version: 11.8.6-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u893187665_team_manager`
--

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action` varchar(50) NOT NULL,
  `table_name` varchar(80) NOT NULL,
  `record_id` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`id`, `user_id`, `action`, `table_name`, `record_id`, `description`, `created_at`) VALUES
(1, 2, 'CREATE', 'bills', 3, 'Created new bill titled: Fuel', '2026-04-08 04:08:19'),
(2, 2, 'CREATE', 'bills', 4, 'Created new bill titled: Tiffin', '2026-04-08 04:09:18'),
(3, 1, 'UPDATE', 'bills', 2, 'Updated bill titled: Payment', '2026-04-08 07:07:36'),
(4, 1, 'CREATE', 'bills', 5, 'Created new bill titled: Bus', '2026-04-08 07:17:22'),
(5, 1, 'CREATE', 'bills', 6, 'Created new bill titled: Bus', '2026-04-08 07:18:13'),
(6, 1, 'UPDATE', 'bills', 6, 'Updated bill titled: Tiffin', '2026-04-08 07:20:32'),
(7, 1, 'UPDATE', 'bills', 6, 'Updated bill titled: Tiffin', '2026-04-08 07:25:50'),
(8, 1, 'CREATE', 'bills', 7, 'Created new bill titled: Water Bottle', '2026-04-08 07:44:33'),
(9, 2, 'CREATE', 'bills', 8, 'Created new bill titled: Food', '2026-04-10 06:57:34'),
(10, 2, 'CREATE', 'bills', 9, 'Created new bill titled: Food', '2026-04-10 07:10:49'),
(11, 2, 'CREATE', 'bills', 10, 'Created new bill titled: Print', '2026-04-10 07:11:19'),
(12, 2, 'CREATE', 'bills', 11, 'Created new bill titled: Food', '2026-04-13 14:20:12'),
(13, 2, 'CREATE', 'bills', 12, 'Created new bill titled: Incubation fee Ag hub', '2026-04-13 14:23:32'),
(14, 2, 'CREATE', 'bills', 13, 'Created new bill titled: Travel', '2026-04-13 14:25:04'),
(15, 2, 'CREATE', 'bills', 14, 'Created new bill titled: Travel', '2026-04-13 14:25:39'),
(16, 1, 'CREATE', 'bills', 15, 'Created new bill titled: Drone Academy Visit', '2026-04-14 01:34:24'),
(17, 1, 'CREATE', 'bills', 16, 'Created new bill titled: Drone Academy Visit', '2026-04-14 01:35:12'),
(18, 1, 'CREATE', 'bills', 17, 'Created new bill titled: Drone Academy Visit', '2026-04-14 01:35:59'),
(19, 1, 'CREATE', 'bills', 18, 'Created new bill titled: Drone Academy', '2026-04-14 01:36:53'),
(20, 1, 'CREATE', 'bills', 19, 'Created new bill titled: Drone Academy Visit', '2026-04-14 01:38:02'),
(21, 1, 'CREATE', 'bills', 20, 'Created new bill titled: Drone Academy Visit', '2026-04-14 01:38:34'),
(22, 1, 'CREATE', 'bills', 21, 'Created new bill titled: Drone Academy Visit', '2026-04-14 01:39:08'),
(23, 1, 'CREATE', 'bills', 22, 'Created new bill titled: Drone Academy Visit', '2026-04-14 01:40:02'),
(24, 1, 'CREATE', 'bills', 23, 'Created new bill titled: Panjagutta visit', '2026-04-14 01:41:13'),
(25, 1, 'CREATE', 'bills', 24, 'Created new bill titled: Panjagutta visit', '2026-04-14 01:42:02'),
(26, 1, 'CREATE', 'bills', 25, 'Created new bill titled: Panjagutta visit', '2026-04-14 01:42:37'),
(27, 1, 'CREATE', 'bills', 26, 'Created new bill titled: Panjagutta visit', '2026-04-14 01:43:38'),
(28, 1, 'CREATE', 'bills', 27, 'Created new bill titled: T Hub', '2026-04-14 01:44:57'),
(29, 1, 'CREATE', 'bills', 28, 'Created new bill titled: T Hub', '2026-04-14 01:45:40'),
(30, 1, 'CREATE', 'bills', 29, 'Created new bill titled: T Hub', '2026-04-14 01:46:59'),
(31, 1, 'CREATE', 'bills', 30, 'Created new bill titled: T Hub', '2026-04-14 01:47:52'),
(32, 1, 'CREATE', 'bills', 31, 'Created new bill titled: OTP Credits', '2026-04-16 05:43:25'),
(33, 1, 'CREATE', 'bills', 32, 'Created new bill titled: Website hosting', '2026-04-16 05:44:06'),
(34, 2, 'CREATE', 'bills', 33, 'Created new bill titled: Bus', '2026-04-19 07:35:45'),
(35, 2, 'UPDATE', 'bills', 33, 'Updated bill titled: Bus', '2026-04-19 07:36:44'),
(36, 2, 'CREATE', 'bills', 34, 'Created new bill titled: Bus', '2026-04-19 07:37:11'),
(37, 2, 'CREATE', 'bills', 35, 'Created new bill titled: Auto', '2026-04-19 07:38:19'),
(38, 2, 'CREATE', 'bills', 36, 'Created new bill titled: Bike air', '2026-04-19 07:39:31'),
(39, 2, 'CREATE', 'bills', 37, 'Created new bill titled: Extension', '2026-04-19 07:40:37'),
(40, 2, 'CREATE', 'bills', 38, 'Created new bill titled: Auto', '2026-04-19 07:43:50'),
(41, 2, 'CREATE', 'bills', 39, 'Created new bill titled: Bus', '2026-04-19 07:44:55'),
(42, 2, 'UPDATE', 'bills', 39, 'Updated bill titled: Bus', '2026-04-19 07:45:09'),
(43, 2, 'UPDATE', 'bills', 34, 'Updated bill titled: Bus', '2026-04-19 07:45:59'),
(44, 2, 'CREATE', 'bills', 40, 'Created new bill titled: Food', '2026-04-19 07:47:48'),
(45, 2, 'CREATE', 'bills', 41, 'Created new bill titled: Bus', '2026-04-19 07:49:18'),
(46, 2, 'CREATE', 'bills', 42, 'Created new bill titled: Food', '2026-04-19 07:49:43'),
(47, 2, 'CREATE', 'bills', 43, 'Created new bill titled: Rapido', '2026-04-22 05:20:22'),
(48, 2, 'CREATE', 'bills', 44, 'Created new bill titled: drone photos', '2026-04-22 05:33:21'),
(49, 2, 'UPDATE', 'bills', 44, 'Updated bill titled: drone photos', '2026-04-22 05:34:24'),
(50, 2, 'UPDATE', 'bills', 44, 'Updated bill titled: drone photos', '2026-04-22 05:35:05'),
(51, 2, 'CREATE', 'bills', 45, 'Created new bill titled: Pertol', '2026-04-22 05:44:18'),
(52, 2, 'CREATE', 'bills', 46, 'Created new bill titled: Food', '2026-04-22 05:44:53'),
(53, 2, 'CREATE', 'bills', 47, 'Created new bill titled: Food', '2026-04-22 05:52:05'),
(54, 2, 'UPDATE', 'bills', 47, 'Updated bill titled: Food', '2026-04-22 05:52:14'),
(55, 2, 'CREATE', 'bills', 48, 'Created new bill titled: Food', '2026-04-22 05:52:51'),
(56, 2, 'CREATE', 'bills', 49, 'Created new bill titled: Food', '2026-04-22 05:53:12'),
(57, 2, 'CREATE', 'bills', 50, 'Created new bill titled: Food', '2026-04-22 05:53:12'),
(58, 2, 'CREATE', 'bills', 51, 'Created new bill titled: Food', '2026-04-22 05:53:37');

-- --------------------------------------------------------

--
-- Table structure for table `bills`
--

CREATE TABLE `bills` (
  `id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `category` varchar(80) NOT NULL DEFAULT 'Other',
  `vendor_name` varchar(150) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `bill_date` date NOT NULL,
  `status` enum('pending','paid','overdue') NOT NULL DEFAULT 'pending',
  `bill_image` text DEFAULT NULL,
  `notes` text NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bills`
--

INSERT INTO `bills` (`id`, `title`, `category`, `vendor_name`, `amount`, `bill_date`, `status`, `bill_image`, `notes`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Ticket', 'Travel', 'Tstrc', 45.00, '2026-04-07', 'paid', 'uploads/bill_1775569318_8546a98a_0.jpg', '0', 1, '2026-04-07 13:41:58', '2026-04-07 13:41:58'),
(2, 'Payment', 'Office', 'R Dhanunjay Reddy', 500.00, '2026-04-07', 'paid', 'uploads/bill_1775569431_a873f196_0.jpg,uploads/Office/bill_system_administrator_1775632056_b08fb7e2_0.jpg', '0', 2, '2026-04-07 13:43:51', '2026-04-08 07:07:36'),
(3, 'Fuel', 'Travel', 'Bankapalli Chandu', 500.00, '2026-04-08', 'paid', 'uploads/bill_1775621299_b4f2d1a5_0.jpg', '', 2, '2026-04-08 04:08:19', '2026-04-08 04:08:19'),
(4, 'Tiffin', 'Food', 'Bankapalli Chandu', 60.00, '2026-04-08', 'paid', 'uploads/bill_1775621358_6485b77e_0.jpg', '', 2, '2026-04-08 04:09:18', '2026-04-08 04:09:18'),
(5, 'Bus', 'Travel', 'Tstrc', 40.00, '2026-04-07', 'paid', 'uploads/Travel/bill_system_administrator_1775632642_5ae3a22a_0.jpg', 'FarmRobo Visit', 1, '2026-04-08 07:17:22', '2026-04-08 07:17:22'),
(6, 'Tiffin', 'Food', 'R Dhanunjay Reddy', 40.00, '2026-04-07', 'paid', 'uploads/Food/bill_system_administrator_1775632693_43689218_0.jpg', 'FarmRobo Visit', 1, '2026-04-08 07:18:13', '2026-04-08 07:25:50'),
(7, 'Water Bottle', 'Food', 'R Dhanunjay Reddy', 20.00, '2026-04-07', 'paid', 'uploads/Food/bill_system_administrator_1775634273_5d48dc48_0.png,uploads/Food/bill_system_administrator_1775634273_03bc650f_1.png', 'Farm Robo Visit', 1, '2026-04-08 07:44:33', '2026-04-08 07:44:33'),
(8, 'Food', 'Food', 'Bankapalli Chandu', 115.00, '2026-04-08', 'paid', 'uploads/Food/bill_b_chandu_1775804254_005eafb8_0.jpg', '', 2, '2026-04-10 06:57:34', '2026-04-10 06:57:34'),
(9, 'Food', 'Food', 'Bankapalli Chandu', 30.00, '2026-04-08', 'paid', 'uploads/Food/bill_b_chandu_1775805049_1a96c771_0.png', '', 2, '2026-04-10 07:10:49', '2026-04-10 07:10:49'),
(10, 'Print', 'Office', 'Bankapalli Chandu', 15.00, '2026-04-09', 'paid', 'uploads/Office/bill_b_chandu_1775805079_55ae749c_0.png', '', 2, '2026-04-10 07:11:19', '2026-04-10 07:11:19'),
(11, 'Food', 'Food', 'Bankapalli Chandu', 160.00, '2026-04-13', 'paid', 'uploads/Food/bill_b_chandu_1776090012_550ca7ac_0.jpg', '', 2, '2026-04-13 14:20:12', '2026-04-13 14:20:12'),
(12, 'Incubation fee Ag hub', 'Office', 'Bankapalli Chandu', 14160.00, '2026-04-13', 'paid', 'uploads/Office/bill_b_chandu_1776090212_adf80fc8_0.jpg', '', 2, '2026-04-13 14:23:32', '2026-04-13 14:23:32'),
(13, 'Travel', 'Travel', 'Bantu pavan', 125.00, '2026-04-07', 'paid', 'uploads/Travel/bill_b_chandu_1776090304_1e2dcd32_0.jpg', '', 2, '2026-04-13 14:25:04', '2026-04-13 14:25:04'),
(14, 'Travel', 'Travel', 'Bantu pavan', 28.00, '2026-04-12', 'paid', 'uploads/Travel/bill_b_chandu_1776090339_9898c623_0.jpg', '', 2, '2026-04-13 14:25:39', '2026-04-13 14:25:39'),
(15, 'Drone Academy Visit', 'Travel', 'Tsrtc', 30.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130464_e030ec98_0.png', '', 1, '2026-04-14 01:34:24', '2026-04-14 01:34:24'),
(16, 'Drone Academy Visit', 'Travel', 'Tsrtc', 40.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130512_18566fa3_0.png', '', 1, '2026-04-14 01:35:12', '2026-04-14 01:35:12'),
(17, 'Drone Academy Visit', 'Food', 'Gulam', 80.00, '2026-04-13', 'paid', 'uploads/Food/bill_system_administrator_1776130559_ba9a680a_0.png', '', 1, '2026-04-14 01:35:59', '2026-04-14 01:35:59'),
(18, 'Drone Academy', 'Travel', 'Bandalaiah', 30.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130613_c897e41e_0.png', 'Auto', 1, '2026-04-14 01:36:53', '2026-04-14 01:36:53'),
(19, 'Drone Academy Visit', 'Travel', 'Sneha', 20.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130682_defb3452_0.png', 'Auto', 1, '2026-04-14 01:38:02', '2026-04-14 01:38:02'),
(20, 'Drone Academy Visit', 'Travel', 'Tsrtc', 40.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130714_cdc9e3c0_0.png', 'Bus', 1, '2026-04-14 01:38:34', '2026-04-14 01:38:34'),
(21, 'Drone Academy Visit', 'Travel', 'Tsrtc', 25.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130748_0db98bde_0.png', 'Bus', 1, '2026-04-14 01:39:08', '2026-04-14 01:39:08'),
(22, 'Drone Academy Visit', 'Food', 'Raj kumar', 50.00, '2026-04-13', 'paid', 'uploads/Food/bill_system_administrator_1776130802_3d2a3b9c_0.png', 'Drink', 1, '2026-04-14 01:40:02', '2026-04-14 01:40:02'),
(23, 'Panjagutta visit', 'Travel', 'Tsrtc', 45.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130873_0c10c15e_0.png', 'Bus', 1, '2026-04-14 01:41:13', '2026-04-14 01:41:13'),
(24, 'Panjagutta visit', 'Travel', 'L&T Metro', 11.00, '2026-04-13', 'paid', 'uploads/Travel/bill_system_administrator_1776130922_1ad8a8fc_0.png', '', 1, '2026-04-14 01:42:02', '2026-04-14 01:42:02'),
(25, 'Panjagutta visit', 'Food', 'Durgarao', 25.00, '2026-04-13', 'paid', 'uploads/Food/bill_system_administrator_1776130957_eb564494_0.png', 'Tiffin', 1, '2026-04-14 01:42:37', '2026-04-14 01:42:37'),
(26, 'Panjagutta visit', 'Food', 'Biryani cafe', 10.00, '2026-04-13', 'paid', 'uploads/Food/bill_system_administrator_1776131018_270a24bb_0.png', 'Water bottle', 1, '2026-04-14 01:43:38', '2026-04-14 01:43:38'),
(27, 'T Hub', 'Travel', 'Manyam', 20.00, '2026-04-10', 'paid', 'uploads/Travel/bill_system_administrator_1776131097_f44bd4a4_0.png', 'Auto', 1, '2026-04-14 01:44:57', '2026-04-14 01:44:57'),
(28, 'T Hub', 'Food', 'Fork & Four', 60.00, '2026-04-10', 'paid', 'uploads/Food/bill_system_administrator_1776131140_e99aed90_0.png', 'Food', 1, '2026-04-14 01:45:40', '2026-04-14 01:45:40'),
(29, 'T Hub', 'Travel', 'Shiva kumar', 20.00, '2026-04-10', 'paid', 'uploads/Travel/bill_system_administrator_1776131219_f47d0451_0.png', 'Auto', 1, '2026-04-14 01:46:59', '2026-04-14 01:46:59'),
(30, 'T Hub', 'Food', 'Harish', 200.00, '2026-04-10', 'paid', 'uploads/Food/bill_system_administrator_1776131272_c803cbda_0.png', 'Food', 1, '2026-04-14 01:47:52', '2026-04-14 01:47:52'),
(31, 'OTP Credits', 'Office', 'MSG91', 590.00, '2026-04-16', 'paid', 'uploads/Office/bill_system_administrator_1776318205_3fed49e2_0.png', '', 1, '2026-04-16 05:43:25', '2026-04-16 05:43:25'),
(32, 'Website hosting', 'Office', 'Hostinger', 5366.00, '2026-04-16', 'paid', 'uploads/Office/bill_system_administrator_1776318246_a9f7cfd7_0.png', '', 1, '2026-04-16 05:44:06', '2026-04-16 05:44:06'),
(33, 'Bus', 'Travel', 'Bankapalli Chandu', 50.00, '2026-04-14', 'paid', 'uploads/Travel/bill_b_chandu_1776584145_e4c30710_0.png', '', 2, '2026-04-19 07:35:45', '2026-04-19 07:36:44'),
(34, 'Bus', 'Travel', 'Bankapalli Chandu', 160.00, '2026-04-14', 'paid', 'uploads/Travel/bill_b_chandu_1776584231_339d1573_0.png', '', 2, '2026-04-19 07:37:11', '2026-04-19 07:45:59'),
(35, 'Auto', 'Travel', 'Bankapalli Chandu', 10.00, '2026-04-14', 'paid', 'uploads/Travel/bill_b_chandu_1776584299_3aac71b3_0.png', '', 2, '2026-04-19 07:38:19', '2026-04-19 07:38:19'),
(36, 'Bike air', 'Travel', 'Bankapalli Chandu', 10.00, '2026-04-14', 'paid', 'uploads/Travel/bill_b_chandu_1776584371_6c6bb1a4_0.png', '', 2, '2026-04-19 07:39:31', '2026-04-19 07:39:31'),
(37, 'Extension', 'Maintenance', 'Bankapalli Chandu', 600.00, '2026-04-14', 'paid', 'uploads/Maintenance/bill_b_chandu_1776584437_5a6507a1_0.png', '', 2, '2026-04-19 07:40:37', '2026-04-19 07:40:37'),
(38, 'Auto', 'Travel', 'Bankapalli Chandu', 20.00, '2026-04-14', 'paid', 'uploads/Travel/bill_b_chandu_1776584630_913a7ff9_0.png', '', 2, '2026-04-19 07:43:50', '2026-04-19 07:43:50'),
(39, 'Bus', 'Travel', 'Bankapalli Chandu', 180.00, '2026-04-14', 'paid', 'uploads/Travel/bill_b_chandu_1776584709_693cad4e_0.png', '', 2, '2026-04-19 07:44:55', '2026-04-19 07:45:09'),
(40, 'Food', 'Food', 'Bankapalli Chandu', 75.00, '2026-04-14', 'paid', 'uploads/Food/bill_b_chandu_1776584868_7f91261e_0.png,uploads/Food/bill_b_chandu_1776584868_0b190769_1.png', '', 2, '2026-04-19 07:47:48', '2026-04-19 07:47:48'),
(41, 'Bus', 'Travel', 'Bankapalli Chandu', 50.00, '2026-04-14', 'paid', 'uploads/Travel/bill_b_chandu_1776584958_cb327ed2_0.png', '', 2, '2026-04-19 07:49:18', '2026-04-19 07:49:18'),
(42, 'Food', 'Food', 'Bankapalli Chandu', 45.00, '2026-04-14', 'paid', 'uploads/Food/bill_b_chandu_1776584983_4ba17a38_0.png', '', 2, '2026-04-19 07:49:43', '2026-04-19 07:49:43'),
(43, 'Rapido', 'Travel', 'Bantu pavan', 200.00, '2026-04-17', 'paid', 'uploads/Travel/bill_b_chandu_1776835222_0a140da9_0.jpg', '', 2, '2026-04-22 05:20:22', '2026-04-22 05:20:22'),
(44, 'drone photos', 'Other', 'Bankapalli chandu', 2000.00, '2026-04-17', 'paid', 'uploads/Other/bill_b_chandu_1776836000_be18c7b1_0.png,uploads/Other/bill_b_chandu_1776836064_70d4edcf_0.png', '2nd file photo', 2, '2026-04-22 05:33:21', '2026-04-22 05:35:05'),
(45, 'Pertol', 'Travel', 'Bankapalli Chandu', 500.00, '2026-04-17', 'paid', 'uploads/Travel/bill_b_chandu_1776836658_a145b3fe_0.jpg', '', 2, '2026-04-22 05:44:18', '2026-04-22 05:44:18'),
(46, 'Food', 'Food', 'Bankapalli Chandu', 130.00, '2026-04-17', 'paid', 'uploads/Food/bill_b_chandu_1776836693_cc7eb57e_0.jpg', '', 2, '2026-04-22 05:44:53', '2026-04-22 05:44:53'),
(47, 'Food', 'Food', 'Bankapalli Chandu', 20.00, '2026-04-17', 'paid', 'uploads/Food/bill_b_chandu_1776837125_74cabce5_0.png', '', 2, '2026-04-22 05:52:05', '2026-04-22 05:52:14'),
(48, 'Food', 'Food', 'Bankapalli Chandu', 90.00, '2026-04-17', 'paid', 'uploads/Food/bill_b_chandu_1776837171_954610dd_0.png', '', 2, '2026-04-22 05:52:51', '2026-04-22 05:52:51'),
(49, 'Food', 'Food', 'Bankapalli Chandu', 10.00, '2026-04-17', 'paid', 'uploads/Food/bill_b_chandu_1776837189_ef553d3a_0.png', '', 2, '2026-04-22 05:53:12', '2026-04-22 05:53:12'),
(50, 'Food', 'Food', 'Bankapalli Chandu', 10.00, '2026-04-17', 'paid', 'uploads/Food/bill_b_chandu_1776837192_62ca76b8_0.png', '', 2, '2026-04-22 05:53:12', '2026-04-22 05:53:12'),
(51, 'Food', 'Food', 'Bankapalli Chandu', 60.00, '2026-04-17', 'paid', 'uploads/Food/bill_b_chandu_1776837217_e1713b8c_0.png', '', 2, '2026-04-22 05:53:37', '2026-04-22 05:53:37');

-- --------------------------------------------------------

--
-- Table structure for table `cinecircle`
--

CREATE TABLE `cinecircle` (
  `id` char(36) NOT NULL,
  `mobile_number` varchar(15) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `account_type` enum('Public','Professional','Company') NOT NULL,
  `status` enum('Active','Suspended','Banned') DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `bio` text DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `role_title` varchar(100) DEFAULT NULL,
  `profile_image_url` varchar(255) DEFAULT NULL,
  `last_login_reward_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cinecircle`
--

INSERT INTO `cinecircle` (`id`, `mobile_number`, `full_name`, `password`, `account_type`, `status`, `created_at`, `updated_at`, `bio`, `city`, `latitude`, `longitude`, `role_title`, `profile_image_url`, `last_login_reward_date`) VALUES
('46132ac1-5abe-4648-b5df-07f98ea87e07', '9182867605', 'Arjun', '$2y$10$tpaDPiMGEfELs4DcEFj6/ujfazjvWi4YZa1mNm6qcq/Z1SL/Y0EsW', 'Public', 'Active', '2026-04-11 13:26:27', '2026-04-27 04:46:45', 'Jack of all traits', 'Hyderabad ', NULL, NULL, 'Director ', 'https://team.cropsync.in/cine_circle/cinecircle_profile/profile_69da6b808d03a.webp', '2026-04-27'),
('4674f122-1b61-452a-88ca-4b8c1b646309', '9247541741', 'Vamsi', '$2y$10$23UOyP0ns4QjOZ5963uO5e6xEHderiaggelPzwLLyFyvot8BnOgs6', 'Public', 'Active', '2026-04-24 08:02:34', '2026-04-24 08:02:35', NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-24'),
('74d6ebe3-fde2-48d6-8cf7-a069a8015cf9', '0000000000', '________________________', '$2y$10$eWQjMutxd3hPt5VYUKPlMuMt6AEfLaGDaCd08sUHErnAd5T.LaRdm', 'Public', 'Active', '2026-04-27 01:35:54', '2026-04-27 01:35:54', NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-27'),
('u1', '9000000001', 'Alex Chen', 'hashed_pw', 'Professional', 'Active', '2026-04-11 16:58:25', '2026-04-11 17:07:41', NULL, 'Los Angeles', NULL, NULL, 'Director', 'https://team.cropsync.in/cine_circle/cinecircle_profile/profile_69da6b808d03a.webp', NULL),
('u2', '9000000002', 'Maya Gupta', 'hashed_pw', 'Professional', 'Active', '2026-04-11 16:58:25', '2026-04-11 17:07:34', NULL, 'Mumbai', NULL, NULL, 'Cinematographer', 'https://team.cropsync.in/cine_circle/cinecircle_profile/profile_69da6b808d03a.webp', NULL),
('u3', '9000000003', 'Rahul Verma', 'hashed_pw', 'Professional', 'Active', '2026-04-11 16:58:25', '2026-04-11 17:07:44', NULL, 'Hyderabad', NULL, NULL, 'Actor', 'https://team.cropsync.in/cine_circle/cinecircle_profile/profile_69da6b808d03a.webp', NULL),
('u4', '9000000004', 'Film Society', 'hashed_pw', 'Company', 'Active', '2026-04-11 16:58:25', '2026-04-11 17:07:47', NULL, 'New York', NULL, NULL, 'Film Community', 'https://team.cropsync.in/cine_circle/cinecircle_profile/profile_69da6b808d03a.webp', NULL),
('u5', '9000000005', 'Casting Collective', 'hashed_pw', 'Company', 'Active', '2026-04-11 16:58:25', '2026-04-11 17:07:38', NULL, 'Mumbai', NULL, NULL, 'Casting Agency', 'https://team.cropsync.in/cine_circle/cinecircle_profile/profile_69da6b808d03a.webp', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `conversations`
--

CREATE TABLE `conversations` (
  `id` char(36) NOT NULL,
  `user1_id` char(36) NOT NULL,
  `user2_id` char(36) NOT NULL,
  `last_message` text DEFAULT NULL,
  `last_message_at` timestamp NULL DEFAULT current_timestamp(),
  `unread_user1` int(11) DEFAULT 0,
  `unread_user2` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `conversations`
--

INSERT INTO `conversations` (`id`, `user1_id`, `user2_id`, `last_message`, `last_message_at`, `unread_user1`, `unread_user2`, `created_at`) VALUES
('2a026fc8-865d-43cf-9863-a7b463d285e6', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u1', NULL, '2026-04-12 04:37:52', 0, 0, '2026-04-12 04:37:52'),
('3531b3c1-6de1-424e-82af-a4e3bd0591e0', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u2', 'Hello', '2026-04-26 11:22:36', 0, 2, '2026-04-12 04:11:28'),
('b8b3d48b-f7d1-4a02-a4ce-88893f861350', '46132ac1-5abe-4648-b5df-07f98ea87e07', '4674f122-1b61-452a-88ca-4b8c1b646309', NULL, '2026-04-26 11:24:05', 0, 0, '2026-04-26 11:24:05'),
('c8b5919c-760a-4393-814f-1dacb7c2b34f', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u5', NULL, '2026-04-12 04:23:57', 0, 0, '2026-04-12 04:23:57'),
('ca5d7571-ff22-4dc9-ba5b-bc4334a930cb', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u3', NULL, '2026-04-12 04:30:49', 0, 0, '2026-04-12 04:30:49');

-- --------------------------------------------------------

--
-- Table structure for table `credit_transactions`
--

CREATE TABLE `credit_transactions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `transaction_type` enum('EARN','SPEND') NOT NULL,
  `activity_type` varchar(50) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `credit_transactions`
--

INSERT INTO `credit_transactions` (`id`, `user_id`, `amount`, `transaction_type`, `activity_type`, `description`, `created_at`) VALUES
(1, 46132, 10, 'EARN', 'POST_CREATED', 'Created a new post in Circle', '2026-04-26 12:26:52'),
(2, 46132, 10, 'EARN', 'POST_CREATED', 'Created a new post in Circle', '2026-04-26 16:16:18');

-- --------------------------------------------------------

--
-- Table structure for table `daily_short_posts`
--

CREATE TABLE `daily_short_posts` (
  `id` char(36) NOT NULL,
  `poster_user_id` char(36) NOT NULL,
  `title` varchar(255) NOT NULL,
  `role_type` enum('Lead','Supporting','Background','Child Artist','Dancer','Voice') NOT NULL,
  `project_type` varchar(100) DEFAULT NULL,
  `shoot_date` varchar(255) DEFAULT NULL,
  `pay_per_day` varchar(100) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_urgent` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `daily_short_posts`
--

INSERT INTO `daily_short_posts` (`id`, `poster_user_id`, `title`, `role_type`, `project_type`, `shoot_date`, `pay_per_day`, `location`, `description`, `image_url`, `is_urgent`, `is_active`, `created_at`) VALUES
('d1', 'u3', 'Need 2 Supporting Actors for Short Film', 'Supporting', 'Short Film', 'Apr 15, 2026', '₹3000/day', 'Hyderabad', 'Quick shoot for student film project.', 'https://example.com/daily/d1.jpg', 1, 1, '2026-04-12 03:11:32'),
('d2', 'u1', 'Background Artists Required', 'Background', 'Music Video', 'Apr 16-17, 2026', '₹1500/day', 'Mumbai', 'Energetic background dancers needed.', 'https://example.com/daily/d2.jpg', 0, 1, '2026-04-12 03:11:32'),
('d3', 'u2', 'Child Artist Needed', 'Child Artist', 'Ad Shoot', 'Apr 18, 2026', '₹4000/day', 'Chennai', 'Looking for expressive child actor.', 'https://example.com/daily/d3.jpg', 1, 1, '2026-04-12 03:11:32');

-- --------------------------------------------------------

--
-- Table structure for table `feed_comments`
--

CREATE TABLE `feed_comments` (
  `id` char(36) NOT NULL,
  `post_id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `comment` text NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `feed_comments`
--

INSERT INTO `feed_comments` (`id`, `post_id`, `user_id`, `comment`, `created_at`) VALUES
('1341e1f2-69b9-48d5-8dee-6088c16c4f27', 'p1', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Super', '2026-04-12 02:24:41'),
('4f9183e9-9c5b-4336-9bdc-ab153065cb92', 'c4d57c00-e7dc-4a95-a564-23df4ff04f8d', '46132ac1-5abe-4648-b5df-07f98ea87e07', '💥', '2026-04-26 11:23:44'),
('c1', 'p1', 'u2', 'Looks amazing! 🔥', '2026-04-11 16:59:03'),
('c2', 'p2', 'u3', 'Interested in auditioning.', '2026-04-11 16:59:03'),
('c3', 'p3', 'u1', 'Great film, excited for this!', '2026-04-11 16:59:03');

-- --------------------------------------------------------

--
-- Table structure for table `feed_likes`
--

CREATE TABLE `feed_likes` (
  `user_id` char(36) NOT NULL,
  `post_id` char(36) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `feed_likes`
--

INSERT INTO `feed_likes` (`user_id`, `post_id`) VALUES
('46132ac1-5abe-4648-b5df-07f98ea87e07', '00285c08-9ecd-4785-8fbd-ff0588228f55'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', '554cd815-bd78-43ba-97c6-eb24a64d8a12'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', '80fb8a9b-2c73-4b98-855f-7cb1eb9fe847'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', '87850c4b-9774-4294-b519-32c611c93cad'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'c4d57c00-e7dc-4a95-a564-23df4ff04f8d'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'e3109788-2135-4656-b24b-601d5ba94613'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'fe71a325-3f2b-4eae-92de-0c2fef358159'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'p1'),
('u2', 'p1'),
('u3', 'p1'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'p2'),
('u1', 'p2'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'p3'),
('u3', 'p3'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'p4'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'p5'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'p6'),
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'p7');

-- --------------------------------------------------------

--
-- Table structure for table `feed_posts`
--

CREATE TABLE `feed_posts` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `category` enum('Project Update','Casting Call','Screening Room','Community Highlight') NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `media_url` varchar(255) DEFAULT NULL,
  `media_type` enum('image','video') DEFAULT 'image',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `feed_posts`
--

INSERT INTO `feed_posts` (`id`, `user_id`, `category`, `title`, `description`, `media_url`, `media_type`, `created_at`) VALUES
('00285c08-9ecd-4785-8fbd-ff0588228f55', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Project Update', 'Hi', '', 'https://team.cropsync.in/cine_circle/uploads/feed/4c5365f4-7778-4f92-89bf-57b1088c2b47.mp4', 'video', '2026-04-12 05:01:32'),
('554cd815-bd78-43ba-97c6-eb24a64d8a12', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Project Update', 'kiosk', '', 'https://team.cropsync.in/cine_circle/uploads/feed/Arjun/4869a0dc-0f45-4153-988a-268b6f72d7fa.mp4', 'video', '2026-04-26 11:24:35'),
('80fb8a9b-2c73-4b98-855f-7cb1eb9fe847', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Project Update', 'Greenary', '', 'https://team.cropsync.in/cine_circle/uploads/feed/Arjun/9d2a1009-c63b-4e73-a3ac-eb25f9813647.jpg', 'image', '2026-04-26 11:26:33'),
('87850c4b-9774-4294-b519-32c611c93cad', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Project Update', 'working', '', 'https://team.cropsync.in/cine_circle/uploads/feed/Arjun/6ada64a2-fb71-44d8-aafe-d949eda644fe.jpg', 'image', '2026-04-26 12:26:51'),
('c4d57c00-e7dc-4a95-a564-23df4ff04f8d', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Project Update', 'cropsync', '', 'https://team.cropsync.in/cine_circle/uploads/feed/Arjun/93060825-64c6-4268-b703-7ab29147e8d7.jpg', 'image', '2026-04-26 11:22:59'),
('e3109788-2135-4656-b24b-601d5ba94613', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Project Update', 'rewards', '', 'https://team.cropsync.in/cine_circle/uploads/feed/Arjun/af267108-397b-4160-bef7-f822fb4913be.jpg', 'image', '2026-04-26 12:11:10'),
('fe71a325-3f2b-4eae-92de-0c2fef358159', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Project Update', 'hi', '', 'https://team.cropsync.in/cine_circle/uploads/feed/Arjun/4941a6e5-eed2-47b4-b3ab-787a84684660.png', 'image', '2026-04-26 16:16:18'),
('p1', 'u1', 'Project Update', 'New York Indie', 'Filming wraps this week. Post-production begins Monday.', 'https://example.com/video1.mp4', 'video', '2026-04-11 14:58:35'),
('p2', 'u5', 'Casting Call', 'Lead Role: The Alchemist', 'Seeking actor 25-35 for feature film. Auditions open.', 'https://example.com/image1.jpg', 'image', '2026-04-11 12:58:35'),
('p3', 'u4', 'Screening Room', 'Lost in Translation Screening', 'Join us for a live Q&A with the director.', 'https://example.com/video2.mp4', 'video', '2026-04-10 16:58:35'),
('p4', 'u4', 'Community Highlight', 'Award Winners Announced', 'Check out the full list of winners from the recent festival.', 'https://example.com/image2.jpg', 'image', '2026-04-09 16:58:35'),
('p5', 'u2', 'Project Update', 'Mumbai Ad Shoot', 'Completed a high-speed commercial shoot with Phantom camera.', 'https://example.com/image3.jpg', 'image', '2026-04-11 13:58:35'),
('p6', 'u3', 'Community Highlight', 'Short Film Festival Selection', 'Our indie film got selected for Hyderabad Indie Fest!', 'https://example.com/image4.jpg', 'image', '2026-04-11 10:58:35'),
('p7', 'u2', 'Screening Room', 'Cinematography Breakdown', 'Watch how we lit this night scene using minimal gear.', 'https://example.com/video3.mp4', 'video', '2026-04-11 08:58:35');

-- --------------------------------------------------------

--
-- Table structure for table `feed_saves`
--

CREATE TABLE `feed_saves` (
  `user_id` char(36) NOT NULL,
  `post_id` char(36) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `feed_views`
--

CREATE TABLE `feed_views` (
  `user_id` char(36) NOT NULL,
  `post_id` char(36) NOT NULL,
  `viewed_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_applications`
--

CREATE TABLE `job_applications` (
  `id` char(36) NOT NULL,
  `applicant_id` char(36) NOT NULL,
  `job_type` enum('casting','daily') NOT NULL,
  `job_id` char(36) NOT NULL,
  `status` enum('Pending','Reviewed','Shortlisted','Rejected','Hired') DEFAULT 'Pending',
  `cover_note` text DEFAULT NULL,
  `applied_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_posts`
--

CREATE TABLE `job_posts` (
  `id` char(36) NOT NULL,
  `poster_user_id` char(36) NOT NULL,
  `title` varchar(255) NOT NULL,
  `company` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `job_type` enum('Casting','Crew','Services','Remote') NOT NULL DEFAULT 'Casting',
  `pay_type` varchar(100) DEFAULT NULL,
  `pay_amount` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `requirements` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`requirements`)),
  `responsibilities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`responsibilities`)),
  `submission_materials` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`submission_materials`)),
  `image_url` varchar(255) DEFAULT NULL,
  `is_urgent` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `deadline` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `job_posts`
--

INSERT INTO `job_posts` (`id`, `poster_user_id`, `title`, `company`, `location`, `job_type`, `pay_type`, `pay_amount`, `description`, `requirements`, `responsibilities`, `submission_materials`, `image_url`, `is_urgent`, `is_active`, `deadline`, `created_at`) VALUES
('j1', 'u1', 'Lead Actor for Indie Feature', 'Moonlight Productions', 'Mumbai', 'Casting', 'Paid', '₹5000/day', 'Looking for a passionate lead actor for an indie feature film.', '[\"Age 25-35\", \"Acting experience required\", \"Fluent in Hindi\"]', '[\"Perform lead role\", \"Attend rehearsals\", \"Collaborate with director\"]', '[\"Resume\", \"Portfolio\", \"Showreel\"]', 'https://example.com/jobs/j1.jpg', 1, 1, '2026-04-19', '2026-04-12 03:11:32'),
('j2', 'u2', 'Cinematographer Needed', 'Urban Frames Studio', 'Hyderabad', 'Crew', 'Contract', '₹8000/day', 'Seeking experienced cinematographer for ad shoot.', '[\"3+ years experience\", \"Own equipment preferred\"]', '[\"Handle camera operations\", \"Lighting setup\"]', '[\"Portfolio\", \"Previous work links\"]', 'https://example.com/jobs/j2.jpg', 0, 1, '2026-04-22', '2026-04-12 03:11:32'),
('j3', 'u4', 'Video Editor (Remote)', 'Film Society', 'Remote', 'Remote', 'Freelance', '$300/project', 'Remote video editor needed for short films.', '[\"Editing skills\", \"Premiere Pro knowledge\"]', '[\"Edit raw footage\", \"Color correction\"]', '[\"Portfolio\"]', 'https://example.com/jobs/j3.jpg', 0, 1, '2026-04-27', '2026-04-12 03:11:32');

-- --------------------------------------------------------

--
-- Table structure for table `job_saves`
--

CREATE TABLE `job_saves` (
  `user_id` char(36) NOT NULL,
  `job_type` enum('casting','daily') NOT NULL,
  `job_id` char(36) NOT NULL,
  `saved_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `job_saves`
--

INSERT INTO `job_saves` (`user_id`, `job_type`, `job_id`, `saved_at`) VALUES
('46132ac1-5abe-4648-b5df-07f98ea87e07', 'daily', 'd1', '2026-04-12 03:12:04');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` char(36) NOT NULL,
  `conversation_id` char(36) NOT NULL,
  `sender_id` char(36) NOT NULL,
  `body` text NOT NULL,
  `media_url` varchar(255) DEFAULT NULL,
  `media_type` enum('image','video','audio') DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `sent_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `conversation_id`, `sender_id`, `body`, `media_url`, `media_type`, `is_read`, `sent_at`) VALUES
('55136653-970b-48bc-a6aa-13c2c22321d6', '3531b3c1-6de1-424e-82af-a4e3bd0591e0', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Hi', NULL, NULL, 0, '2026-04-12 04:11:33'),
('a24e81da-70bd-44f7-b22e-f57da3f14237', '3531b3c1-6de1-424e-82af-a4e3bd0591e0', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Hello', NULL, NULL, 0, '2026-04-26 11:22:36');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `actor_id` char(36) DEFAULT NULL,
  `type` enum('follow','profile_view','message','post_like','post_comment','job_match','job_application','daily_quiz','reward_redeemed','system') NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `body` text DEFAULT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` char(36) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `actor_id`, `type`, `title`, `body`, `entity_type`, `entity_id`, `is_read`, `created_at`) VALUES
('04d2bdc4-27aa-451a-ab3e-8a66630e7407', 'u2', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-26 11:23:54'),
('0a589755-c331-4e4b-96f0-ec606c1c1464', 'u3', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:03:58'),
('13d2961c-3dc4-4924-9905-bbf24940ff7e', 'u1', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:03:39'),
('1f287615-ee30-46a9-a93e-e48dadb12b7c', 'u3', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-19 09:06:31'),
('3df300f1-f9d1-4d1d-a0b4-004b76f60c54', 'u2', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'message', 'Arjun sent you a message', 'Hello', 'conversation', '3531b3c1-6de1-424e-82af-a4e3bd0591e0', 0, '2026-04-26 11:22:36'),
('5ce9a48a-775f-4a35-8287-05bd59b8b5e1', 'u3', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:11:51'),
('6d8a91ff-a8a5-4005-8194-ebbf9f379771', 'u4', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 05:16:47'),
('707741f1-80b4-4447-ad9c-dba217b95433', 'u1', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:11:55'),
('7519a9dc-347d-4210-8af8-6b1c61367bd6', 'u2', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:11:27'),
('77f05066-9eee-4037-b8e9-ba43201fb5a6', '4674f122-1b61-452a-88ca-4b8c1b646309', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-26 11:23:56'),
('7869d2e2-d5d2-4667-9d9c-e2941223fd47', 'u2', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:11:22'),
('7c6aa6db-4925-46a2-a590-de65f57c967d', '4674f122-1b61-452a-88ca-4b8c1b646309', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-26 11:23:59'),
('8790e795-855c-4361-b0ca-fa9fa78201ca', 'u2', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:24:02'),
('88aa9751-ee26-48c1-a01f-a531e9920334', 'u5', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:24:17'),
('9cfa0c36-e80a-4cae-8179-ac3f9182e22e', 'u2', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'message', 'Arjun sent you a message', 'Hi', 'conversation', '3531b3c1-6de1-424e-82af-a4e3bd0591e0', 0, '2026-04-12 04:11:33'),
('9d045163-ee95-45da-9184-3ece9c352512', 'u4', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-13 10:58:58'),
('b73d9851-ad67-4af5-8273-828f735844a8', 'u5', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:23:48'),
('cd79ebde-3d7b-466d-b00e-65967092fffa', 'u4', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-26 11:23:53'),
('ed773e0a-afcf-47b8-ae09-6c3eb2dd16f6', 'u5', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'profile_view', 'Arjun viewed your profile', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:11:57'),
('f02f4f1e-27ec-4bf7-8b8d-7708d35a9e9c', 'u2', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'follow', 'Arjun started following you', '', 'profile', '46132ac1-5abe-4648-b5df-07f98ea87e07', 0, '2026-04-12 04:25:35');

-- --------------------------------------------------------

--
-- Table structure for table `profile_views`
--

CREATE TABLE `profile_views` (
  `id` char(36) NOT NULL,
  `viewer_id` char(36) NOT NULL,
  `profile_id` char(36) NOT NULL,
  `viewed_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `profile_views`
--

INSERT INTO `profile_views` (`id`, `viewer_id`, `profile_id`, `viewed_at`) VALUES
('215db7f2-c149-4a51-8ad5-1fc71723ae73', '46132ac1-5abe-4648-b5df-07f98ea87e07', '4674f122-1b61-452a-88ca-4b8c1b646309', '2026-04-26 11:24:02'),
('c101a7e6-b80a-4356-9271-193b865bce1a', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u1', '2026-04-12 08:40:47'),
('207c3eb2-2112-47a6-813f-d079264ea911', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u2', '2026-04-12 08:40:49'),
('0c27b082-a675-44a1-8364-75b27fa1c8a5', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u3', '2026-04-12 08:40:40'),
('fc2deae7-91eb-48f0-922d-8558913fe780', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u3', '2026-04-19 09:06:31'),
('84ce6f11-f0e0-48c7-b180-b852d866c093', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u4', '2026-04-12 05:16:47'),
('6317a78a-60cd-4d71-ba05-64f8eeb860d0', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u4', '2026-04-13 10:58:58'),
('9fc21e86-4e87-4b10-8b5c-24eb3adc9ae9', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u5', '2026-04-12 05:43:15');

-- --------------------------------------------------------

--
-- Table structure for table `redemptions`
--

CREATE TABLE `redemptions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `reward_id` int(11) DEFAULT NULL,
  `status` enum('PENDING','COMPLETED','EXPIRED') DEFAULT 'PENDING',
  `redeemed_at` timestamp NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reward_catalog`
--

CREATE TABLE `reward_catalog` (
  `id` int(11) NOT NULL,
  `reward_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `cost_credits` int(11) NOT NULL,
  `reward_type` enum('TICKET','MERCH','BADGE','PREMIUM') NOT NULL,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `reward_catalog`
--

INSERT INTO `reward_catalog` (`id`, `reward_name`, `description`, `cost_credits`, `reward_type`, `is_active`) VALUES
(1, 'Movie Voucher - PVR ₹200', 'Redeemable at PVR Cinemas for any movie ticket worth ₹200.', 150, 'TICKET', 1),
(2, 'Movie Voucher - INOX ₹300', 'Valid for booking tickets at INOX theaters across India.', 220, 'TICKET', 1),
(3, 'Custom Phone Case', 'Personalized phone case with your name or design.', 300, 'MERCH', 1),
(4, 'CropSync Branded T-Shirt', 'High-quality cotton t-shirt with CropSync branding.', 250, 'MERCH', 1),
(5, 'Premium Subscription - 1 Month', 'Unlock premium features for 30 days.', 500, 'PREMIUM', 1),
(6, 'Premium Subscription - 3 Months', 'Access all premium features for 90 days.', 1200, 'PREMIUM', 1),
(7, 'Gold Farmer Badge', 'Exclusive badge for top-performing farmers.', 100, 'BADGE', 1),
(8, 'Early Adopter Badge', 'Awarded to early users of the CropSync platform.', 50, 'BADGE', 1),
(9, 'Amazon Gift Card ₹500', 'Use on Amazon India for a wide range of products.', 450, 'TICKET', 1),
(10, 'Bluetooth Earbuds', 'Wireless earbuds with high-quality sound.', 800, 'MERCH', 1);

-- --------------------------------------------------------

--
-- Table structure for table `reward_items`
--

CREATE TABLE `reward_items` (
  `id` char(36) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `icon_name` varchar(100) DEFAULT NULL,
  `category` enum('Merchandise','Movie Tickets','Event Passes','Fan Drops','Premium') NOT NULL,
  `credits_cost` int(11) NOT NULL,
  `stock_quantity` int(11) DEFAULT NULL,
  `stock_label` varchar(100) DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `reward_items`
--

INSERT INTO `reward_items` (`id`, `title`, `description`, `image_url`, `icon_name`, `category`, `credits_cost`, `stock_quantity`, `stock_label`, `is_available`, `created_at`) VALUES
('r1', 'CineCircle T-Shirt', 'Premium cotton t-shirt with CineCircle branding.', 'https://example.com/rewards/tshirt.jpg', 'checkroom', 'Merchandise', 150, 50, 'Limited Stock', 1, '2026-04-12 02:55:48'),
('r10', 'Early Access to Casting Calls', 'Get priority access to top casting opportunities.', 'https://example.com/rewards/early.jpg', 'bolt', 'Premium', 450, NULL, 'Unlimited', 1, '2026-04-12 02:55:48'),
('r2', 'Film Crew Cap', 'Stylish cap for filmmakers and creators.', 'https://example.com/rewards/cap.jpg', 'checkroom', 'Merchandise', 10, 97, 'Available Now', 1, '2026-04-12 02:55:48'),
('r3', 'Movie Ticket Voucher', 'Redeem for a free movie ticket at partner cinemas.', 'https://example.com/rewards/ticket.jpg', 'local_activity', 'Movie Tickets', 200, NULL, 'Unlimited', 1, '2026-04-12 02:55:48'),
('r4', 'Premium IMAX Ticket', 'Enjoy a premium IMAX experience.', 'https://example.com/rewards/imax.jpg', 'local_activity', 'Movie Tickets', 350, 20, 'Limited Seats', 1, '2026-04-12 02:55:48'),
('r5', 'Film Festival Pass', 'Access to exclusive indie film festival screenings.', 'https://example.com/rewards/festival.jpg', 'event', 'Event Passes', 500, 10, 'Limited Access', 1, '2026-04-12 02:55:48'),
('r6', 'Workshop Entry Pass', 'Attend a filmmaking workshop by industry experts.', 'https://example.com/rewards/workshop.jpg', 'event', 'Event Passes', 300, 25, 'Available Now', 1, '2026-04-12 02:55:48'),
('r7', 'Signed Movie Poster', 'Limited edition signed poster from a blockbuster film.', 'https://example.com/rewards/poster.jpg', 'star', 'Fan Drops', 400, 5, 'Very Limited', 1, '2026-04-12 02:55:48'),
('r8', 'Behind-the-Scenes Access', 'Exclusive behind-the-scenes digital content.', 'https://example.com/rewards/bts.jpg', 'visibility', 'Fan Drops', 250, NULL, 'Unlimited', 1, '2026-04-12 02:55:48'),
('r9', 'Pro Membership Upgrade', 'Unlock premium features for 30 days.', 'https://example.com/rewards/pro.jpg', 'workspace_premium', 'Premium', 600, NULL, 'Unlimited', 1, '2026-04-12 02:55:48');

-- --------------------------------------------------------

--
-- Table structure for table `social_credits`
--

CREATE TABLE `social_credits` (
  `user_id` int(11) NOT NULL,
  `mobile_number` varchar(15) DEFAULT NULL,
  `current_balance` int(11) DEFAULT 0,
  `total_earned` int(11) DEFAULT 0,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `social_credits`
--

INSERT INTO `social_credits` (`user_id`, `mobile_number`, `current_balance`, `total_earned`, `updated_at`) VALUES
(46132, '9182867605', 20, 20, '2026-04-26 16:16:18');

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `assignee_id` int(11) DEFAULT NULL,
  `priority` enum('Low','Medium','High') NOT NULL DEFAULT 'Medium',
  `status` enum('To Do','In Progress','Done') NOT NULL DEFAULT 'To Do',
  `due_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `tasks`
--

INSERT INTO `tasks` (`id`, `title`, `description`, `assignee_id`, `priority`, `status`, `due_date`, `created_at`) VALUES
(11, 'Dvara E Dairy', 'AFTER FARMERS COUNT AND OPERATING LOCATIONS\nCattle Insurance Discussion', 1, 'High', 'In Progress', '2025-10-22', '2025-10-15 05:52:00'),
(12, 'Agriculture Insurance Company of India', 'AFTER FARMERS COUNT AND OPERATING LOCATIONS\nBranch Visit for crop insurance discussion', 5, 'High', 'In Progress', '2025-10-31', '2025-10-15 05:52:54'),
(13, 'Crop Advisory Validation', 'AgHub, Manage, & ICAR Naarm Visits, but prior linkedin interaction', 1, 'High', 'To Do', '2025-10-31', '2025-10-15 05:54:38'),
(14, 'CropSync App Developement', '', 1, 'Medium', 'In Progress', '2025-10-31', '2025-10-15 05:55:13'),
(15, 'Tractor Sync APP developement', '', 1, 'Medium', 'In Progress', '2025-11-30', '2025-10-15 05:55:51'),
(16, 'Retailer APP Development', '', 1, 'Medium', 'In Progress', '2025-11-15', '2025-10-15 05:56:23'),
(18, 'Social Media Engagement & online presence', 'Post Regularly to increase Presence', 7, 'High', 'To Do', '2026-01-10', '2025-10-15 06:11:55'),
(27, 'Identify the Potential Social media influencers', 'From platforms like Instagram, Facebook, youtube, Etc.. \nMake an Excel sheet, list there profiles with info and possible ways to connect.', 7, 'High', 'To Do', '2025-11-11', '2025-10-31 02:39:33'),
(28, 'Seed Companies List', 'Seed company, address, date of visit, response, contact person and number', 5, 'Low', 'To Do', '2025-11-02', '2025-11-01 04:27:54'),
(30, 'Birac', 'https://birac.nic.in/cfp_view.php?id=32&scheme_type=5](https://birac.nic.in/cfp_view.php?id=32&scheme_type=5)\nWAITING FOR MAIL.', 5, 'Medium', 'In Progress', '2025-11-14', '2025-11-03 12:19:37'),
(32, 'TRADEMARK & IP RIGHTS', 'SHOULD BE Initiated as soon as possible', 1, 'High', 'To Do', '2026-01-30', '2026-01-02 02:12:11'),
(33, 'Shares update & CA Filings', 'CA related Compliances ', 5, 'Medium', 'To Do', NULL, '2026-01-02 02:16:04'),
(34, 'Katangur FPO visit', 'Schedule visits and update progress ', 5, 'High', 'To Do', '2026-01-05', '2026-01-02 02:19:05'),
(36, 'FPO groups & Chemicals Data', 'Should identify the FPO\'s connection channels \n&\nCollection of chemicals data from available sources for crops', 5, 'High', 'To Do', '2026-01-15', '2026-01-02 02:29:06');

-- --------------------------------------------------------

--
-- Table structure for table `team_members`
--

CREATE TABLE `team_members` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `initials` varchar(5) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `team_members`
--

INSERT INTO `team_members` (`id`, `name`, `initials`, `username`, `email`, `password_hash`) VALUES
(1, 'R Dhanunjay Reddy', 'DJ', 'dhanunjay', 'rearjun284@gmail.com', '$2y$10$VdTSQvxEzniZwJU09ojSiO5EBw0GJzRiMnWNwxfL12P1u/FMORqzK'),
(5, 'B Chandu', 'BC', 'chandu', 'bankapallichandu4@gmail.com', '$2y$10$O29QPs0tO16bplsOuMkE5ea65NhwVB75fiCh3do4HdkK3.hJo/o4G'),
(7, 'B Pavan', 'BP', 'pavan', 'bantupavan79284@gmail.com', '$2y$10$oPpFpZFTql91j/MoEo9a3.Ty1yfh7N0x4UxGUatPY.X3hRvsOQ6t6'),
(8, 'Saketh', 'Sa', 'saketh', '20mgt8ab015@vgu.ac.in', '$2y$10$wHauTHuY3Hw2qyQJ30WLge/GDjItlaTWgWmAp4PNKWzOrEkAfIjLW');

-- --------------------------------------------------------

--
-- Table structure for table `trivia_categories`
--

CREATE TABLE `trivia_categories` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `icon_name` varchar(100) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `credits_reward` int(11) NOT NULL DEFAULT 10,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trivia_categories`
--

INSERT INTO `trivia_categories` (`id`, `name`, `icon_name`, `image_url`, `credits_reward`, `is_active`) VALUES
(1, 'Movies', 'movie', 'https://example.com/cat_movies.jpg', 10, 1),
(2, 'Directors', 'director', 'https://example.com/cat_directors.jpg', 10, 1),
(3, 'Awards', 'award', 'https://example.com/cat_awards.jpg', 10, 1);

-- --------------------------------------------------------

--
-- Table structure for table `trivia_challenges`
--

CREATE TABLE `trivia_challenges` (
  `id` char(36) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `credits_reward` int(11) NOT NULL DEFAULT 25,
  `is_daily` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `valid_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trivia_challenges`
--

INSERT INTO `trivia_challenges` (`id`, `category_id`, `title`, `description`, `image_url`, `credits_reward`, `is_daily`, `is_active`, `valid_date`) VALUES
('ch1', NULL, 'Today\'s Bonus Trivia', 'Answer all questions correctly to win bonus credits.', 'https://example.com/ch_daily.jpg', 25, 1, 1, '2026-04-12'),
('ch2', 1, 'Movie Buff Challenge', 'Test your knowledge of blockbuster films.', 'https://example.com/ch_movies.jpg', 20, 0, 1, NULL),
('ch3', 2, 'Director Genius', 'How well do you know legendary directors?', 'https://example.com/ch_directors.jpg', 20, 0, 1, NULL),
('ch4', 3, 'Awards Master', 'Only true cinephiles know these awards!', 'https://example.com/ch_awards.jpg', 20, 0, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `trivia_challenge_questions`
--

CREATE TABLE `trivia_challenge_questions` (
  `challenge_id` char(36) NOT NULL,
  `question_id` char(36) NOT NULL,
  `sort_order` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trivia_challenge_questions`
--

INSERT INTO `trivia_challenge_questions` (`challenge_id`, `question_id`, `sort_order`) VALUES
('ch1', 'q1', 1),
('ch1', 'q3', 2),
('ch1', 'q5', 3),
('ch2', 'q1', 1),
('ch2', 'q2', 2),
('ch3', 'q3', 1),
('ch3', 'q4', 2),
('ch4', 'q5', 1),
('ch4', 'q6', 2);

-- --------------------------------------------------------

--
-- Table structure for table `trivia_questions`
--

CREATE TABLE `trivia_questions` (
  `id` char(36) NOT NULL,
  `category_id` int(11) NOT NULL,
  `question_text` text NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `option_a` varchar(255) NOT NULL,
  `option_b` varchar(255) NOT NULL,
  `option_c` varchar(255) NOT NULL,
  `option_d` varchar(255) NOT NULL,
  `correct_option` enum('A','B','C','D') NOT NULL,
  `difficulty` enum('easy','medium','hard') DEFAULT 'medium',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trivia_questions`
--

INSERT INTO `trivia_questions` (`id`, `category_id`, `question_text`, `image_url`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `difficulty`, `created_at`) VALUES
('q1', 1, 'Which movie features the quote \"I am your father\"?', NULL, 'Star Wars', 'The Matrix', 'Inception', 'Avatar', 'A', 'medium', '2026-04-12 02:34:59'),
('q2', 1, 'Which film won Best Picture in 2020?', NULL, '1917', 'Parasite', 'Joker', 'Ford v Ferrari', 'B', 'medium', '2026-04-12 02:34:59'),
('q3', 2, 'Who directed \"Inception\"?', NULL, 'Christopher Nolan', 'Steven Spielberg', 'James Cameron', 'Quentin Tarantino', 'A', 'medium', '2026-04-12 02:34:59'),
('q4', 2, 'Which director is known for \"Pulp Fiction\"?', NULL, 'Martin Scorsese', 'Quentin Tarantino', 'Ridley Scott', 'Guy Ritchie', 'B', 'medium', '2026-04-12 02:34:59'),
('q5', 3, 'Which award is considered the highest in cinema?', NULL, 'BAFTA', 'Golden Globe', 'Oscar', 'Emmy', 'C', 'medium', '2026-04-12 02:34:59'),
('q6', 3, 'Which film won multiple Oscars in 1997?', NULL, 'Titanic', 'Gladiator', 'Braveheart', 'The Godfather', 'A', 'medium', '2026-04-12 02:34:59');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','member') NOT NULL DEFAULT 'member',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `full_name`, `email`, `password`, `role`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'System Administrator', 'ceo@cropsync.in', 'Wdgmdatp0.', 'admin', 1, '2026-04-07 12:10:06', '2026-04-07 12:10:06'),
(2, 'B Chandu', 'director@cropsync.in', 'Chandu@2002', 'member', 1, '2026-04-07 12:48:20', '2026-04-07 13:21:14'),
(3, 'B Pavan', 'info@cropsync.in', 'Pavan@2002', 'member', 1, '2026-04-07 13:23:43', '2026-04-07 13:23:43');

-- --------------------------------------------------------

--
-- Table structure for table `user_credits`
--

CREATE TABLE `user_credits` (
  `id` bigint(20) NOT NULL,
  `user_id` char(36) NOT NULL,
  `project_title` varchar(255) NOT NULL,
  `role` varchar(100) NOT NULL,
  `year` year(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_credits`
--

INSERT INTO `user_credits` (`id`, `user_id`, `project_title`, `role`, `year`) VALUES
(1, '46132ac1-5abe-4648-b5df-07f98ea87e07', 'CropSync', 'CEO', '2024');

-- --------------------------------------------------------

--
-- Table structure for table `user_credits_history`
--

CREATE TABLE `user_credits_history` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `type` enum('earn','spend') NOT NULL,
  `source` enum('quiz_win','daily_login','engagement','review_reward','redemption','early_access','unlock') NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `amount` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_credits_history`
--

INSERT INTO `user_credits_history` (`id`, `user_id`, `type`, `source`, `title`, `amount`, `created_at`) VALUES
('02e76b38-812c-4e51-be17-657b15afb2cf', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-12 18:37:26'),
('2ad6c8ab-97b2-42f0-ac5f-71ba7396ee2f', '4674f122-1b61-452a-88ca-4b8c1b646309', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-24 08:02:35'),
('2af657bf-b082-4c86-ae3e-8bbcf20046aa', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'quiz_win', 'Quiz Win: Director Genius', 10, '2026-04-12 03:02:19'),
('3a3a55db-04b3-4bb3-ad4a-31e3cc2b8733', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'quiz_win', 'Quiz Win: Today\'s Bonus Trivia', 17, '2026-04-12 02:44:50'),
('3ab65ac8-9f83-44d2-ad4f-14902a8495e7', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'quiz_win', 'Quiz Win: Awards Master', 20, '2026-04-26 10:21:25'),
('4d029255-3c2d-4720-afa8-ba5410da9de1', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-21 12:08:09'),
('57552072-27b0-425d-9ff2-30cf511b3d7a', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-24 03:55:56'),
('60d61500-e58b-4eec-89b4-6463f986da34', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'spend', 'redemption', 'Redeemed: Film Crew Cap', -10, '2026-04-26 11:22:14'),
('64f468ee-d28e-46d2-9bc1-582c6abbfb07', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'quiz_win', 'Quiz Win: Director Genius', 20, '2026-04-26 14:52:45'),
('71a72cd9-6027-4d28-a365-b3ddd092ca0a', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-14 06:02:07'),
('975d8a27-8eb2-43a2-a4ea-451ec16056bb', '74d6ebe3-fde2-48d6-8cf7-a069a8015cf9', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-27 01:35:54'),
('a2bd7bce-ec2e-469b-bcd5-c9664f95381c', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-26 08:08:20'),
('a82df26c-93ff-4b56-9f8d-89da0e76c5ce', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'spend', 'redemption', 'Redeemed: Film Crew Cap', -10, '2026-04-26 14:52:56'),
('b45401ca-f825-426d-a8fe-3df5cb9210e9', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-12 02:43:45'),
('dab2bbf8-df9a-4e69-9999-923332ad803e', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-27 04:46:45'),
('dab6869f-a90d-4076-a85f-b6d7f56df141', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-19 09:06:21'),
('ec884a48-c126-489c-a24d-1c5ec1aac4aa', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'spend', 'redemption', 'Redeemed: Film Crew Cap', -10, '2026-04-12 02:56:55'),
('ecfe8afa-02b5-4aed-ba3b-7f9d56136c37', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-22 12:10:36'),
('ef2ac27f-d6b1-47e6-859f-35f2d574ff52', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'earn', 'daily_login', 'Daily Login Bonus', 5, '2026-04-16 10:04:29');

-- --------------------------------------------------------

--
-- Table structure for table `user_credits_ledger`
--

CREATE TABLE `user_credits_ledger` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `balance` int(11) DEFAULT 0,
  `total_earned` int(11) DEFAULT 0,
  `total_spent` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_credits_ledger`
--

INSERT INTO `user_credits_ledger` (`id`, `user_id`, `balance`, `total_earned`, `total_spent`) VALUES
('86bf158d-1843-4174-8e4b-522b1d931725', '4674f122-1b61-452a-88ca-4b8c1b646309', 5, 5, 0),
('cfc4c528-b648-46c9-aa19-c4bb38457c50', '74d6ebe3-fde2-48d6-8cf7-a069a8015cf9', 5, 5, 0),
('d92c3825-5d58-474f-a06a-ce7c2aaa99b7', '46132ac1-5abe-4648-b5df-07f98ea87e07', 87, 117, 30);

-- --------------------------------------------------------

--
-- Table structure for table `user_follows`
--

CREATE TABLE `user_follows` (
  `id` char(36) NOT NULL,
  `follower_id` char(36) NOT NULL,
  `following_id` char(36) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_follows`
--

INSERT INTO `user_follows` (`id`, `follower_id`, `following_id`, `created_at`) VALUES
('0c8ad6a2-afe5-4e87-95e3-b32ea312ec94', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u1', '2026-04-12 04:03:39'),
('31d4ae99-d6ca-4ddd-985e-61d495735dbb', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u5', '2026-04-12 04:24:17'),
('7764a25a-1fb2-406c-b0ff-6b2b9973aa56', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u3', '2026-04-12 04:03:58'),
('aaadff13-4b12-4a34-b8aa-d7e9c3c0822a', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u4', '2026-04-26 11:23:53'),
('c5fcf87b-63cb-4000-a6fc-f2069b361ee1', '46132ac1-5abe-4648-b5df-07f98ea87e07', '4674f122-1b61-452a-88ca-4b8c1b646309', '2026-04-26 11:23:56'),
('d21dbb41-f466-43ad-a1b2-8ab915bd3530', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'u2', '2026-04-26 11:23:54');

-- --------------------------------------------------------

--
-- Table structure for table `user_portfolio`
--

CREATE TABLE `user_portfolio` (
  `id` bigint(20) NOT NULL,
  `user_id` char(36) NOT NULL,
  `media_url` varchar(255) NOT NULL,
  `title` varchar(150) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_portfolio`
--

INSERT INTO `user_portfolio` (`id`, `user_id`, `media_url`, `title`, `description`, `created_at`) VALUES
(1, '46132ac1-5abe-4648-b5df-07f98ea87e07', 'https://team.cropsync.in/cine_circle/cinecircle_featuredreel/reel_69da6ba6227e8.mp4', 'Cropsync ', 'Pilot Trails ', '2026-04-11 15:41:26');

-- --------------------------------------------------------

--
-- Table structure for table `user_redemptions`
--

CREATE TABLE `user_redemptions` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `item_id` char(36) NOT NULL,
  `credits_spent` int(11) NOT NULL,
  `status` enum('Pending','Completed','Failed','Cancelled') DEFAULT 'Pending',
  `redeemed_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_redemptions`
--

INSERT INTO `user_redemptions` (`id`, `user_id`, `item_id`, `credits_spent`, `status`, `redeemed_at`) VALUES
('af4eb86c-26e8-4f6c-b30c-fbdca381c2c9', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'r2', 10, 'Pending', '2026-04-26 11:22:14'),
('b544bf69-7062-448c-a3d4-237c4eb3357c', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'r2', 10, 'Pending', '2026-04-26 14:52:56'),
('c6b8aef2-9097-4c2c-892a-80bd8fb69049', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'r2', 10, 'Pending', '2026-04-12 02:56:55');

-- --------------------------------------------------------

--
-- Table structure for table `user_skills`
--

CREATE TABLE `user_skills` (
  `id` bigint(20) NOT NULL,
  `user_id` char(36) NOT NULL,
  `skill_name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_skills`
--

INSERT INTO `user_skills` (`id`, `user_id`, `skill_name`) VALUES
(1, '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Director'),
(2, '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Photography '),
(3, '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Camera'),
(4, '46132ac1-5abe-4648-b5df-07f98ea87e07', 'Lights ');

-- --------------------------------------------------------

--
-- Table structure for table `user_trivia_attempts`
--

CREATE TABLE `user_trivia_attempts` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `challenge_id` char(36) NOT NULL,
  `score` int(11) DEFAULT 0,
  `total_questions` int(11) DEFAULT 0,
  `credits_earned` int(11) DEFAULT 0,
  `completed` tinyint(1) DEFAULT 0,
  `attempted_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_trivia_attempts`
--

INSERT INTO `user_trivia_attempts` (`id`, `user_id`, `challenge_id`, `score`, `total_questions`, `credits_earned`, `completed`, `attempted_at`) VALUES
('18f25628-c7cc-44dc-945c-473f39f9a9e3', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ch3', 2, 2, 20, 1, '2026-04-26 14:52:45'),
('19b9eb55-64e6-4038-9956-44148833b720', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ch1', 2, 3, 17, 1, '2026-04-12 02:44:50'),
('2430a070-e2f9-4958-87a2-336172aa5f8f', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ch2', 0, 2, 0, 1, '2026-04-26 10:21:05'),
('7f6f6124-cd75-45ae-8ca0-5b8f320867bc', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ch2', 0, 2, 0, 1, '2026-04-12 02:44:30'),
('aecf2ea9-151a-46bb-b1a0-ad3a17803777', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ch4', 2, 2, 20, 1, '2026-04-26 10:21:25'),
('f202481a-83c3-404c-ab02-631ccf0dd2df', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ch3', 1, 2, 10, 1, '2026-04-12 03:02:19');

-- --------------------------------------------------------

--
-- Table structure for table `webseries`
--

CREATE TABLE `webseries` (
  `id` varchar(36) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `genre` varchar(100) DEFAULT NULL,
  `tags` varchar(500) DEFAULT NULL,
  `status` enum('ONGOING','COMPLETED','UPCOMING') DEFAULT 'ONGOING',
  `type` enum('SERIES','SHORT') DEFAULT 'SERIES',
  `cover_url` varchar(500) DEFAULT NULL,
  `banner_url` varchar(500) DEFAULT NULL,
  `trailer_url` varchar(500) DEFAULT NULL,
  `language` varchar(50) DEFAULT 'Telugu',
  `total_episodes` int(11) DEFAULT 0,
  `avg_duration_min` int(11) DEFAULT 0,
  `created_by` varchar(36) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `webseries`
--

INSERT INTO `webseries` (`id`, `title`, `description`, `genre`, `tags`, `status`, `type`, `cover_url`, `banner_url`, `trailer_url`, `language`, `total_episodes`, `avg_duration_min`, `created_by`, `is_active`, `created_at`, `updated_at`) VALUES
('ws_69ee46a67f166', 'Cropsync', 'a full pledged startup story', 'Drama', '', 'ONGOING', 'SERIES', 'uploads/1777223334_69ee46a67f17e.png', 'uploads/1777223334_69ee46a67fbfd.jpeg', NULL, 'Telugu', 2, 0, NULL, 1, '2026-04-26 17:08:54', '2026-04-26 17:10:37');

-- --------------------------------------------------------

--
-- Table structure for table `webseries_episodes`
--

CREATE TABLE `webseries_episodes` (
  `id` varchar(36) NOT NULL,
  `series_id` varchar(36) NOT NULL,
  `episode_number` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `video_url` varchar(500) DEFAULT NULL,
  `thumbnail_url` varchar(500) DEFAULT NULL,
  `duration_sec` int(11) DEFAULT 0,
  `is_premium` tinyint(1) DEFAULT 0,
  `credits_cost` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `sort_order` int(11) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `webseries_episodes`
--

INSERT INTO `webseries_episodes` (`id`, `series_id`, `episode_number`, `title`, `description`, `video_url`, `thumbnail_url`, `duration_sec`, `is_premium`, `credits_cost`, `is_active`, `sort_order`, `created_at`) VALUES
('ep_69ee46e03bcfb', 'ws_69ee46a67f166', 1, 'Introduction ', '', 'uploads/videos/1777223392_69ee46e03bf36.mp4', 'uploads/1777223392_69ee46e03e8ed.png', 45, 0, 0, 1, 0, '2026-04-26 17:09:52'),
('ep_69ee470d3963e', 'ws_69ee46a67f166', 2, 'Begining', '', 'uploads/videos/1777223437_69ee470d39800.mp4', 'uploads/1777223437_69ee470d3aad2.webp', 30, 0, 0, 1, 0, '2026-04-26 17:10:37');

-- --------------------------------------------------------

--
-- Table structure for table `webseries_reactions`
--

CREATE TABLE `webseries_reactions` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `episode_id` varchar(36) NOT NULL,
  `type` enum('LIKE','COMMENT','SHARE') NOT NULL,
  `body` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `webseries_reactions`
--

INSERT INTO `webseries_reactions` (`id`, `user_id`, `episode_id`, `type`, `body`, `created_at`) VALUES
('7cbea1f9-462a-4fd7-9e83-4c9718dca68d', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ep_69ee46e03bcfb', 'COMMENT', '♥️', '2026-04-26 18:19:47'),
('9ee1fa82-b0e1-4abe-ba3b-6d8a3214b002', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ep_69ee470d3963e', 'LIKE', NULL, '2026-04-26 18:19:58'),
('ce363116-92bf-4962-afff-b9a1a54e2702', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ep_69ee46e03bcfb', 'LIKE', NULL, '2026-04-26 18:19:41');

-- --------------------------------------------------------

--
-- Table structure for table `webseries_watchlist`
--

CREATE TABLE `webseries_watchlist` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `series_id` varchar(36) NOT NULL,
  `added_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `webseries_watch_progress`
--

CREATE TABLE `webseries_watch_progress` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `series_id` varchar(36) NOT NULL,
  `episode_id` varchar(36) NOT NULL,
  `watched_sec` int(11) DEFAULT 0,
  `is_completed` tinyint(1) DEFAULT 0,
  `last_watched` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `webseries_watch_progress`
--

INSERT INTO `webseries_watch_progress` (`id`, `user_id`, `series_id`, `episode_id`, `watched_sec`, `is_completed`, `last_watched`) VALUES
('1594b2a1-81b8-438b-be0b-2a69f39b08ec', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ws_69ee46a67f166', 'ep_69ee46e03bcfb', 42, 0, '2026-04-27 14:36:33'),
('e5a0794f-68ad-40c7-b308-12c16a6f1f9e', '46132ac1-5abe-4648-b5df-07f98ea87e07', 'ws_69ee46a67f166', 'ep_69ee470d3963e', 9, 0, '2026-04-27 14:36:21');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_logs_user` (`user_id`);

--
-- Indexes for table `bills`
--
ALTER TABLE `bills`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_bills_user` (`created_by`);

--
-- Indexes for table `cinecircle`
--
ALTER TABLE `cinecircle`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `mobile_number` (`mobile_number`);

--
-- Indexes for table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_conv_pair` (`user1_id`,`user2_id`),
  ADD KEY `idx_conv_user1` (`user1_id`),
  ADD KEY `idx_conv_user2` (`user2_id`),
  ADD KEY `idx_conv_last_msg` (`last_message_at`);

--
-- Indexes for table `credit_transactions`
--
ALTER TABLE `credit_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `daily_short_posts`
--
ALTER TABLE `daily_short_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_daily_role` (`role_type`),
  ADD KEY `idx_daily_active` (`is_active`),
  ADD KEY `idx_daily_created` (`created_at`),
  ADD KEY `poster_user_id` (`poster_user_id`);

--
-- Indexes for table `feed_comments`
--
ALTER TABLE `feed_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_comment_post` (`post_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `feed_likes`
--
ALTER TABLE `feed_likes`
  ADD PRIMARY KEY (`user_id`,`post_id`),
  ADD KEY `post_id` (`post_id`);

--
-- Indexes for table `feed_posts`
--
ALTER TABLE `feed_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_feed_user` (`user_id`),
  ADD KEY `idx_feed_created` (`created_at`);

--
-- Indexes for table `feed_saves`
--
ALTER TABLE `feed_saves`
  ADD PRIMARY KEY (`user_id`,`post_id`),
  ADD KEY `post_id` (`post_id`);

--
-- Indexes for table `feed_views`
--
ALTER TABLE `feed_views`
  ADD PRIMARY KEY (`user_id`,`post_id`);

--
-- Indexes for table `job_applications`
--
ALTER TABLE `job_applications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_app_applicant` (`applicant_id`),
  ADD KEY `idx_app_job` (`job_id`),
  ADD KEY `idx_app_status` (`status`);

--
-- Indexes for table `job_posts`
--
ALTER TABLE `job_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobs_type` (`job_type`),
  ADD KEY `idx_jobs_active` (`is_active`),
  ADD KEY `idx_jobs_created` (`created_at`),
  ADD KEY `poster_user_id` (`poster_user_id`);

--
-- Indexes for table `job_saves`
--
ALTER TABLE `job_saves`
  ADD PRIMARY KEY (`user_id`,`job_type`,`job_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_msg_conv` (`conversation_id`,`sent_at`),
  ADD KEY `idx_msg_sender` (`sender_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notif_user` (`user_id`,`is_read`),
  ADD KEY `idx_notif_created` (`created_at`),
  ADD KEY `actor_id` (`actor_id`);

--
-- Indexes for table `profile_views`
--
ALTER TABLE `profile_views`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_view_daily` (`viewer_id`,`profile_id`,`viewed_at`),
  ADD KEY `idx_pv_profile` (`profile_id`),
  ADD KEY `idx_pv_viewer` (`viewer_id`),
  ADD KEY `idx_pv_time` (`viewed_at`);

--
-- Indexes for table `redemptions`
--
ALTER TABLE `redemptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `reward_id` (`reward_id`);

--
-- Indexes for table `reward_catalog`
--
ALTER TABLE `reward_catalog`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `reward_items`
--
ALTER TABLE `reward_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rewards_category` (`category`),
  ADD KEY `idx_rewards_available` (`is_available`);

--
-- Indexes for table `social_credits`
--
ALTER TABLE `social_credits`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `mobile_number` (`mobile_number`);

--
-- Indexes for table `tasks`
--
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `assignee_id` (`assignee_id`);

--
-- Indexes for table `team_members`
--
ALTER TABLE `team_members`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `trivia_categories`
--
ALTER TABLE `trivia_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `trivia_challenges`
--
ALTER TABLE `trivia_challenges`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_challenge_daily` (`valid_date`,`is_active`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `trivia_challenge_questions`
--
ALTER TABLE `trivia_challenge_questions`
  ADD PRIMARY KEY (`challenge_id`,`question_id`),
  ADD KEY `question_id` (`question_id`);

--
-- Indexes for table `trivia_questions`
--
ALTER TABLE `trivia_questions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tq_category` (`category_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_credits`
--
ALTER TABLE `user_credits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_credits_user` (`user_id`);

--
-- Indexes for table `user_credits_history`
--
ALTER TABLE `user_credits_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ch_user` (`user_id`);

--
-- Indexes for table `user_credits_ledger`
--
ALTER TABLE `user_credits_ledger`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `user_follows`
--
ALTER TABLE `user_follows`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_follow` (`follower_id`,`following_id`),
  ADD KEY `idx_follows_following` (`following_id`),
  ADD KEY `idx_follows_follower` (`follower_id`);

--
-- Indexes for table `user_portfolio`
--
ALTER TABLE `user_portfolio`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_portfolio_user` (`user_id`);

--
-- Indexes for table `user_redemptions`
--
ALTER TABLE `user_redemptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_redemptions_user` (`user_id`),
  ADD KEY `idx_redemptions_item` (`item_id`);

--
-- Indexes for table `user_skills`
--
ALTER TABLE `user_skills`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_skills_user` (`user_id`),
  ADD KEY `idx_skill_name` (`skill_name`);

--
-- Indexes for table `user_trivia_attempts`
--
ALTER TABLE `user_trivia_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_attempt_user` (`user_id`),
  ADD KEY `idx_attempt_challenge` (`challenge_id`),
  ADD KEY `idx_attempt_daily` (`user_id`,`challenge_id`,`attempted_at`);

--
-- Indexes for table `webseries`
--
ALTER TABLE `webseries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `webseries_episodes`
--
ALTER TABLE `webseries_episodes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_series_ep` (`series_id`,`episode_number`),
  ADD KEY `idx_series` (`series_id`);

--
-- Indexes for table `webseries_reactions`
--
ALTER TABLE `webseries_reactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ep` (`episode_id`);

--
-- Indexes for table `webseries_watchlist`
--
ALTER TABLE `webseries_watchlist`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_series` (`user_id`,`series_id`);

--
-- Indexes for table `webseries_watch_progress`
--
ALTER TABLE `webseries_watch_progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_ep` (`user_id`,`episode_id`),
  ADD KEY `idx_user_series` (`user_id`,`series_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- AUTO_INCREMENT for table `bills`
--
ALTER TABLE `bills`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `credit_transactions`
--
ALTER TABLE `credit_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `redemptions`
--
ALTER TABLE `redemptions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reward_catalog`
--
ALTER TABLE `reward_catalog`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `team_members`
--
ALTER TABLE `team_members`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `trivia_categories`
--
ALTER TABLE `trivia_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `user_credits`
--
ALTER TABLE `user_credits`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_portfolio`
--
ALTER TABLE `user_portfolio`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_skills`
--
ALTER TABLE `user_skills`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `fk_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `bills`
--
ALTER TABLE `bills`
  ADD CONSTRAINT `fk_bills_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `conversations`
--
ALTER TABLE `conversations`
  ADD CONSTRAINT `conversations_ibfk_1` FOREIGN KEY (`user1_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `conversations_ibfk_2` FOREIGN KEY (`user2_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `credit_transactions`
--
ALTER TABLE `credit_transactions`
  ADD CONSTRAINT `credit_transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `social_credits` (`user_id`);

--
-- Constraints for table `daily_short_posts`
--
ALTER TABLE `daily_short_posts`
  ADD CONSTRAINT `daily_short_posts_ibfk_1` FOREIGN KEY (`poster_user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `feed_comments`
--
ALTER TABLE `feed_comments`
  ADD CONSTRAINT `feed_comments_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `feed_posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `feed_comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `feed_likes`
--
ALTER TABLE `feed_likes`
  ADD CONSTRAINT `feed_likes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `feed_likes_ibfk_2` FOREIGN KEY (`post_id`) REFERENCES `feed_posts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `feed_posts`
--
ALTER TABLE `feed_posts`
  ADD CONSTRAINT `feed_posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `feed_saves`
--
ALTER TABLE `feed_saves`
  ADD CONSTRAINT `feed_saves_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `feed_saves_ibfk_2` FOREIGN KEY (`post_id`) REFERENCES `feed_posts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `job_applications`
--
ALTER TABLE `job_applications`
  ADD CONSTRAINT `job_applications_ibfk_1` FOREIGN KEY (`applicant_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `job_posts`
--
ALTER TABLE `job_posts`
  ADD CONSTRAINT `job_posts_ibfk_1` FOREIGN KEY (`poster_user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `job_saves`
--
ALTER TABLE `job_saves`
  ADD CONSTRAINT `job_saves_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`actor_id`) REFERENCES `cinecircle` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `profile_views`
--
ALTER TABLE `profile_views`
  ADD CONSTRAINT `profile_views_ibfk_1` FOREIGN KEY (`viewer_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `profile_views_ibfk_2` FOREIGN KEY (`profile_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `redemptions`
--
ALTER TABLE `redemptions`
  ADD CONSTRAINT `redemptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `social_credits` (`user_id`),
  ADD CONSTRAINT `redemptions_ibfk_2` FOREIGN KEY (`reward_id`) REFERENCES `reward_catalog` (`id`);

--
-- Constraints for table `tasks`
--
ALTER TABLE `tasks`
  ADD CONSTRAINT `tasks_ibfk_1` FOREIGN KEY (`assignee_id`) REFERENCES `team_members` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `trivia_challenges`
--
ALTER TABLE `trivia_challenges`
  ADD CONSTRAINT `trivia_challenges_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `trivia_categories` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `trivia_challenge_questions`
--
ALTER TABLE `trivia_challenge_questions`
  ADD CONSTRAINT `trivia_challenge_questions_ibfk_1` FOREIGN KEY (`challenge_id`) REFERENCES `trivia_challenges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `trivia_challenge_questions_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `trivia_questions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `trivia_questions`
--
ALTER TABLE `trivia_questions`
  ADD CONSTRAINT `trivia_questions_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `trivia_categories` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_credits`
--
ALTER TABLE `user_credits`
  ADD CONSTRAINT `user_credits_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_credits_history`
--
ALTER TABLE `user_credits_history`
  ADD CONSTRAINT `user_credits_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_credits_ledger`
--
ALTER TABLE `user_credits_ledger`
  ADD CONSTRAINT `user_credits_ledger_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_follows`
--
ALTER TABLE `user_follows`
  ADD CONSTRAINT `user_follows_ibfk_1` FOREIGN KEY (`follower_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_follows_ibfk_2` FOREIGN KEY (`following_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_portfolio`
--
ALTER TABLE `user_portfolio`
  ADD CONSTRAINT `user_portfolio_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_redemptions`
--
ALTER TABLE `user_redemptions`
  ADD CONSTRAINT `user_redemptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_redemptions_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `reward_items` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_skills`
--
ALTER TABLE `user_skills`
  ADD CONSTRAINT `user_skills_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_trivia_attempts`
--
ALTER TABLE `user_trivia_attempts`
  ADD CONSTRAINT `user_trivia_attempts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `cinecircle` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_trivia_attempts_ibfk_2` FOREIGN KEY (`challenge_id`) REFERENCES `trivia_challenges` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
