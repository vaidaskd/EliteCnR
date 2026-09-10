-- CnR player database export
-- Generated 2026-06-29T19:11:44.220Z
-- Schema matches resources/cnr/server/persistence.lua.
-- Import in phpMyAdmin (Import tab) or: mysql dbname < players.sql

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `players`;
CREATE TABLE `players` (
  `license` VARCHAR(80) NOT NULL,
  `side` VARCHAR(16) NOT NULL DEFAULT 'none',
  `cash` INT NOT NULL DEFAULT 0,
  `credits` INT NOT NULL DEFAULT 0,
  `outfit` INT NOT NULL DEFAULT 1,
  `jail_seconds_remaining` INT NOT NULL DEFAULT 0,
  `jail_debt_seconds` INT NOT NULL DEFAULT 0,
  `jail_facility` VARCHAR(64) NOT NULL DEFAULT '',
  `station` VARCHAR(64) NOT NULL DEFAULT '',
  `hide_hat` TINYINT(1) NOT NULL DEFAULT 0,
  `cop_car_fined` TINYINT(1) NOT NULL DEFAULT 0,
  `skin` JSON NULL,
  `weapons` JSON NULL,
  `weapon_ammo` JSON NULL,
  `tattoos` JSON NULL,
  `inventory` JSON NULL,
  `cop_clothes` JSON NULL,
  `stats` JSON NULL,
  `last_pos` JSON NULL,
  `extra` JSON NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `players`
  (`license`, `side`, `cash`, `credits`, `outfit`, `jail_seconds_remaining`, `jail_debt_seconds`, `jail_facility`, `station`, `hide_hat`, `cop_car_fined`, `skin`, `weapons`, `weapon_ammo`, `tattoos`, `inventory`, `cop_clothes`, `stats`, `last_pos`, `extra`)
VALUES
  ('license:66a11e11a340213fb9d3efa9ed51b58bbd30f500', 'robber', 0, 0, 1, 0, 0, '', '', 0, 0, '{"watch":-1,"pantsTxt":1,"hatTxt":0,"maskTxt":0,"father":12,"pants":50,"hat":-1,"beard":0,"glassesTxt":0,"undershirt":15,"mother":3,"eyes":26,"top":34,"shoesTxt":11,"arms":0,"shoes":93,"beardColor":3,"gender":"male","shapeMix":0.44547723524284,"undershirtTxt":0,"glasses":-1,"hair":30,"skinMix":0.61959989007095,"mask":0,"watchTxt":0,"hairColor":57,"topTxt":1,"isCustom":true}', '["WEAPON_PISTOL"]', '{"WEAPON_PISTOL":100}', '[]', '[]', 'null', '{"stdArrests":0,"instantArrests":0,"robberKills":0}', '{"y":2584.37109375,"x":1856.4428710938,"h":0,"z":45.672008514404}', 'null'),
  ('license:c1944c5a88f4c7a053651fab2cf87025cb4119c3', 'robber', 0, 0, 1, 0, 0, '', '', 0, 0, '{"watch":-1,"pantsTxt":0,"hatTxt":0,"isCustom":true,"father":0,"pants":0,"glasses":-1,"beard":0,"glassesTxt":0,"undershirt":15,"maskTxt":0,"shoes":3,"top":0,"hairColor":2,"arms":0,"shapeMix":0.5,"beardColor":0,"gender":"male","shoesTxt":0,"hat":-1,"undershirtTxt":0,"hair":4,"skinMix":0.5,"mask":0,"watchTxt":0,"eyes":0,"topTxt":0,"mother":0}', '["WEAPON_PISTOL"]', '{"WEAPON_PISTOL":100}', '[]', '[]', 'null', '{"stdArrests":0,"instantArrests":0,"robberKills":0}', '{"y":-886.505859375,"x":-1068.6320800781,"h":0,"z":4.5845594406128}', 'null');

SET FOREIGN_KEY_CHECKS = 1;
