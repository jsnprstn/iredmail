#
# Table `realtime_quota`. Used for Dovecot to store realtime quota.
#
# WARNING: Works only with Dovecot 1.2.x.
#
CREATE TABLE IF NOT EXISTS used_quota (
    `username` VARCHAR(255) NOT NULL,
    `bytes` BIGINT NOT NULL DEFAULT 0,
    `messages` BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
