### begin - web of '<?php echo $domainname; ?>' - do not remove/modify this line

<?php

if (($webcache === 'none') || (!$webcache)) {
    $ports[] = '80';
    $ports[] = '443';
} else {
    $ports[] = '8080';
    $ports[] = '8443';
}

foreach ($certnamelist as $ip => $certname) {
    if (file_exists("/home/{$user}/ssl/{$domainname}.key")) {
        $certnamelist[$ip] = "/home/{$user}/ssl/{$domainname}";
    } else {
        $certnamelist[$ip] = "/home/kloxo/httpd/ssl/{$certname}";
    }
}

$statsapp = $stats['app'];
$statsprotect = ($stats['protect']) ? true : false;

$serveralias = "{$domainname} www.{$domainname}";

$excludedomains = array(
    "cp",
    "webmail"
);

$excludealias = implode("|", $excludedomains);

if ($wildcards) {
    $serveralias .= "\n        *.{$domainname}";
}

if ($serveraliases) {
    foreach ($serveraliases as &$sa) {
        $serveralias .= "\n        {$sa}";
    }
}

if ($parkdomains) {
    foreach ($parkdomains as $pk) {
        $pa = $pk['parkdomain'];
        $serveralias .= "\n        {$pa} www.{$pa}";
    }
}

if ($webmailapp) {
    if ($webmailapp === '--Disabled--') {
        $webmaildocroot = "/home/kloxo/httpd/disable";
    } else {
        $webmaildocroot = "/home/kloxo/httpd/webmail/{$webmailapp}";
    }
} else {
    $webmaildocroot = "/home/kloxo/httpd/webmail";
}

$webmailremote = str_replace("http://", "", $webmailremote);
$webmailremote = str_replace("https://", "", $webmailremote);

if ($indexorder) {
    $indexorder = implode(' ', $indexorder);
}

if ($blockips) {
    $biptemp = array();
    foreach ($blockips as &$bip) {
        if (strpos($bip, ".*.*.*") !== false) {
            $bip = str_replace(".*.*.*", ".0.0/8", $bip);
        }
        if (strpos($bip, ".*.*") !== false) {
            $bip = str_replace(".*.*", ".0.0/16", $bip);
        }
        if (strpos($bip, ".*") !== false) {
            $bip = str_replace(".*", ".0/24", $bip);
        }
        $biptemp[] = $bip;
    }
    $blockips = $biptemp;
}

$userinfo = posix_getpwnam($user);

if ($userinfo) {
    $fpmport = (50000 + $userinfo['uid']);
} else {
    return false;
}

// MR -- for future purpose, apache user have uid 50000
// $userinfoapache = posix_getpwnam('apache');
// $fpmportapache = (50000 + $userinfoapache['uid']);
$fpmportapache = 50000;

exec("ip -6 addr show", $out);

if ($out[0]) {
    $IPv6Enable = true;
} else {
    $IPv6Enable = false;
}

$disabledocroot = "/home/kloxo/httpd/disable";

$globalspath = "/home/nginx/conf/globals";

if (file_exists("{$globalspath}/custom.proxy.conf")) {
    $proxyconf = 'custom.proxy.conf';
} else {
    $wppath = "{$rootpath}/_sitetype_/wordpress";

    if (file_exists($wppath)) {
        $proxyconf = 'wp-proxy.conf';
    } else {
        $proxyconf = 'proxy.conf';
    }
}

if (file_exists("{$globalspath}/custom.php-fpm.conf")) {
    $phpfpmconf = 'custom.php-fpm.conf';
} else {
    $phpfpmconf = 'php-fpm.conf';
}

if (file_exists("{$globalspath}/custom.perl.conf")) {
    $perlconf = 'custom.perl.conf';
} else {
    $perlconf = 'perl.conf';
}

if (file_exists("{$globalspath}/custom.generic.conf")) {
    $genericconf = 'custom.generic.conf';
} else {
    $genericconf = 'generic.conf';
}

if (file_exists("{$globalspath}/custom.awstats.conf")) {
    $awstatsconf = 'custom.awstats.conf';
} else {
    $awstatsconf = 'awstats.conf';
}

if (file_exists("{$globalspath}/custom.dirprotect.conf")) {
    $dirprotectconf = 'custom.dirprotect.conf';
} else {
    $dirprotectconf = 'dirprotect.conf';
}

if (file_exists("{$globalspath}/custom.webalizer.conf")) {
    $webalizerconf = 'custom.webalizer.conf';
} else {
    $webalizerconf = 'webalizer.conf';
}

if ($disabled) {
    $sockuser = 'apache';
} else {
    $sockuser = $user;
}

$count = 0;

foreach ($certnamelist as $ip => $certname) {
    $count = 0;

    foreach ($ports as &$port) {
        $protocol = ($count === 0) ? "http://" : "https://";


        if ($disabled) {
?>

## webmail for '<?php echo $domainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
            if ($ip === '*') {
                if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                }
            } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
            }

            if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
            }
?>

    server_name webmail.<?php echo $domainname; ?>;

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $disabledocroot; ?>';

    root $rootdir;
<?php
            if ($reverseproxy) {
?>

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
            } else {
?>

    set $user 'apache';
    set $fpmport '<?php echo $fpmportapache; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
            }
?>
}

<?php
        } else {
            if ($webmailremote) {
?>

## webmail for '<?php echo $domainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                if ($ip === '*') {
                    if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                    } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                    }
                } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                }

                if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                }
?>

    server_name webmail.<?php echo $domainname; ?>;

    if ($host != '<?php echo $webmailremote; ?>') {
        rewrite ^/(.*) '<?php echo $protocol; ?><?php echo $webmailremote; ?>/$1' permanent;
    }
}

<?php
            } else {
?>

## webmail for '<?php echo $domainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                if ($ip === '*') {
                    if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                    } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                    }
                } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                }

                if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                }
?>

    server_name webmail.<?php echo $domainname; ?>;

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $webmaildocroot; ?>';

    root $rootdir;
<?php
                if ($reverseproxy) {
?>

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
                } else {
?>

    set $user 'apache';
    set $fpmport '<?php echo $fpmportapache; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
                }
?>
}

<?php
            }
        }
?>

## web for '<?php echo $domainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
        if ($ip === '*') {
            if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
            } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
            }
        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
        }

        if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
        }
?>

    server_name <?php echo $serveralias; ?>;

    index <?php echo $indexorder; ?>;

    set $domain '<?php echo $domainname; ?>';
<?php
        if ($wwwredirect) {
?>

    if ($host ~* ^(<?php echo $domainname; ?>)$) {
        rewrite ^/(.*) '<?php echo $protocol; ?>www.<?php echo $domainname; ?>/$1' permanent;
    }
<?php
        }

        if ($disabled) {
?>

    set $rootdir '<?php echo $disabledocroot; ?>';
<?php
        } else {
            if ($wildcards) {
?>

    set $rootdir '<?php echo $rootpath; ?>';
<?php
                foreach ($excludedomains as &$ed) {
?>

    if ($host ~* ^(<?php echo $ed; ?>.<?php echo $domainname; ?>)$) {
<?php
                    if ($ed !== 'webmail') {
?>
        set $rootdir '/home/kloxo/httpd/<?php echo $ed; ?>/';
<?php
                    } else {
                        if ($webmailremote) {
?>
        rewrite ^/(.*) '<?php echo $protocol; ?><?php echo $webmailremote; ?>/$1' permanent;
<?php
                        } else {
?>
        set $rootdir '<?php echo $webmaildocroot; ?>';
<?php
                        }
                    }
?>
    }
<?php
                }
            } else {
?>

    set $rootdir '<?php echo $rootpath; ?>';
<?php
            }
        }
?>

    root $rootdir;
<?php
        if ($redirectionlocal) {
            foreach ($redirectionlocal as $rl) {
?>

    location ~ ^<?php echo $rl[0]; ?>/(.*)$ {
        alias <?php echo str_replace("//", "/", $rl[1]); ?>/$1;
    }
<?php
            }
        }

        if ($redirectionremote) {
            foreach ($redirectionremote as $rr) {
                if ($rr[0] === '/') {
                    $rr[0] = '';
                }
                if ($rr[2] === 'both') {
?>

    rewrite ^<?php echo $rr[0]; ?>/(.*) '<?php echo $protocol; ?><?php echo $rr[1]; ?>/$1' permanent;
<?php
                } else {
                    $protocol2 = ($rr[2] === 'https') ? "https://" : "http://";
?>

    rewrite ^<?php echo $rr[0]; ?>/(.*) '<?php echo $protocol2; ?><?php echo $rr[1]; ?>/$1' permanent;
<?php
                }
            }
        }
?>

    set $user '<?php echo $sockuser; ?>';
<?php
        if (!$reverseproxy) {
?>

    access_log /home/httpd/<?php echo $domainname; ?>/stats/<?php echo $domainname; ?>-custom_log main;
    error_log  /home/httpd/<?php echo $domainname; ?>/stats/<?php echo $domainname; ?>-error_log;
<?php
            if ($statsapp === 'awstats') {
?>

    set $statstype 'awstats';

    include '<?php echo $globalspath; ?>/<?php echo $awstatsconf; ?>';
<?php
                if ($statsprotect) {
?>

    set $protectpath     'awstats';
    set $protectauthname 'Awstats';
    set $protectfile     '__stats';

    include '<?php echo $globalspath; ?>/<?php echo $dirprotectconf; ?>';
<?php
                }
            } elseif ($statsapp === 'webalizer') {
?>

    set $statstype 'stats';

    include '<?php echo $globalspath; ?>/<?php echo $webalizerconf; ?>';
<?php
                if ($statsprotect) {
?>

    set $protectpath     'stats';
    set $protectauthname 'stats';
    set $protectfile     '__stats';

    include '<?php echo $globalspath; ?>/<?php echo $dirprotectconf; ?>';
<?php
                }
            }
        }

        if ($nginxextratext) {
?>

    # Extra Tags - begin
    <?php echo $nginxextratext; ?>

    # Extra Tags - end
<?php
        }

        if (!$disablephp) {
            if ($reverseproxy) {
?>

    set $fpmport '<?php echo $fpmport; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
            } else {
                if ($wildcards) {
?>

    #if ($host !~* ^((<?php echo $excludealias; ?>).<?php echo $domainname; ?>)$) {
        set $fpmport '<?php echo $fpmport; ?>';
    #}

    if ($host ~* ^((<?php echo $excludealias; ?>).<?php echo $domainname; ?>)$) {
        set $fpmport '<?php echo $fpmportapache; ?>';
    }
<?php
                } else {
?>

    set $fpmport '<?php echo $fpmport; ?>';
<?php
                }
?>

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
            }
        }

        if ($dirprotect) {
            foreach ($dirprotect as $k) {
                $protectpath = $k['path'];
                $protectauthname = $k['authname'];
                $protectfile = str_replace('/', '_', $protectpath) . '_';
?>

    location /<?php echo $protectpath; ?>/(.*)$ {
        satisfy any;
        auth_basic '<?php echo $protectauthname; ?>';
        auth_basic_user_file '/home/httpd/<?php echo $domainname; ?>/__dirprotect/<?php echo $protectfile; ?>';
    }
<?php
            }
        }

        if ($blockips) {
?>

    location ^~ /(.*) {
<?php
            foreach ($blockips as &$bip) {
?>
        deny   <?php echo $bip; ?>;
<?php
            }
?>
        allow  all;
    }
<?php
        }
?>

    include '<?php echo $globalspath; ?>/<?php echo $genericconf; ?>';
}

<?php

        if ($domainredirect) {
            foreach ($domainredirect as $domredir) {
                $redirdomainname = $domredir['redirdomain'];
                $redirpath = ($domredir['redirpath']) ? $domredir['redirpath'] : null;
                $webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

                if ($redirpath) {
                    if ($disabled) {
                        $$redirfullpath = $disablepath;
                    } else {
                        $redirfullpath = str_replace('//', '/', $rootpath . '/' . $redirpath);
                    }
?>

## web for redirect '<?php echo $redirdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                    if ($ip === '*') {
                        if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }
                    } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                    }

                    if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                    }
?>

    server_name <?php echo $redirdomainname; ?> www.<?php echo $redirdomainname; ?>;

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $redirfullpath; ?>';

    root $rootdir;
<?php
                    if ($reverseproxy) {
?>

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
                    } else {
?>

    set $user '<?php echo $sockuser; ?>';
    set $fpmport '<?php echo $fpmport; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
                    }
?>
}

<?php
                } else {
                    if ($disabled) {
                        $$redirfullpath = $disablepath;
                    } else {
                        $redirfullpath = $rootpath;
                    }
?>

## web for redirect '<?php echo $redirdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                    if ($ip === '*') {
                        if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }
                    } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                    }

                    if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                    }
?>

    server_name <?php echo $redirdomainname; ?> www.<?php echo $redirdomainname; ?>;

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $redirfullpath; ?>';

    root $rootdir;

    if ($host != '<?php echo $domainname; ?>') {
        rewrite ^/(.*) '<?php echo $protocol; ?><?php echo $domainname; ?>/$1';
    }
}

<?php
                }
            }
        }

        if ($parkdomains) {
            foreach ($parkdomains as $dompark) {
                $parkdomainname = $dompark['parkdomain'];
                $webmailmap = ($dompark['mailflag'] === 'on') ? true : false;

                if ($disabled) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                    if ($ip === '*') {
                        if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }
                    } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                    }

                    if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                    }
?>

    server_name 'webmail.<?php echo $parkdomainname; ?>';

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $disabledocroot; ?>';

    root $rootdir;
<?php
                    if ($reverseproxy) {
?>

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
                    } else {
?>

    set $user 'apache';
    set $fpmport '<?php echo $fpmportapache; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
                    }
?>
}

<?php
                } else {
                    if ($webmailremote) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                        if ($ip === '*') {
                            if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                            } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                            }
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }

                        if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                        }
?>

    server_name 'webmail.<?php echo $parkdomainname; ?>';

    if ($host != '<?php echo $webmailremote; ?>') {
        rewrite ^/(.*) '<?php echo $protocol; ?><?php echo $webmailremote; ?>/$1';
    }
}

<?php

                    } elseif ($webmailmap) {

?>

## webmail for parked '<?php echo $parkdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                        if ($ip === '*') {
                            if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                            } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                            }
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }

                        if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                        }
?>

    server_name 'webmail.<?php echo $parkdomainname; ?>';

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $webmaildocroot; ?>';

    root $rootdir;
<?php
                        if ($reverseproxy) {
?>

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
                        } else {
?>

    set $user 'apache';
    set $fpmport '<?php echo $fpmportapache; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
                        }
?>
}

<?php

                    } else {
?>

## No mail map for parked '<?php echo $parkdomainname; ?>'

<?php
                    }
                }
            }
        }

        if ($domainredirect) {
            foreach ($domainredirect as $domredir) {
                $redirdomainname = $domredir['redirdomain'];
                $webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

                if ($disabled) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                    if ($ip === '*') {
                        if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }
                    } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                    }

                    if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                    }
?>

    server_name 'webmail.<?php echo $redirdomainname; ?>';

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $disabledocroot; ?>';

    root $rootdir;
<?php
                    if ($reverseproxy) {
?>

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
                    } else {
?>

    set $user 'apache';
    set $fpmport '<?php echo $fpmportapache; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
                    }
?>
}

<?php
                } else {
                    if ($webmailremote) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                        if ($ip === '*') {
                            if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                            } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                            }
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }

                        if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                        }
?>

    server_name 'webmail.<?php echo $redirdomainname; ?>';

    if ($host != '<?php echo $webmailremote; ?>') {
        rewrite ^/(.*) '<?php echo $protocol; ?><?php echo $webmailremote; ?>/$1';
    }
}

<?php
                    } elseif ($webmailmap) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
server {
    disable_symlinks if_not_owner;

<?php
                        if ($ip === '*') {
                            if ($IPv6Enable) {
?>
    listen 0.0.0.0:<?php echo $port; ?>;
    listen [::]:<?php echo $port; ?>;
<?php
                            } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                            }
                        } else {
?>
    listen <?php echo $ip; ?>:<?php echo $port; ?>;
<?php
                        }

                        if ($count !== 0) {
?>

    ssl on;
    ssl_certificate <?php echo $certname; ?>.pem;
    ssl_certificate_key <?php echo $certname; ?>.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
<?php
                        }
?>

    server_name 'webmail.<?php echo $redirdomainname; ?>';

    index <?php echo $indexorder; ?>;

    set $rootdir '<?php echo $webmaildocroot; ?>';

    root $rootdir;
<?php
                        if ($reverseproxy) {
?>

    include '<?php echo $globalspath; ?>/<?php echo $proxyconf; ?>';
<?php
                        } else {
?>

    set $user 'apache';
    set $fpmport '<?php echo $fpmportapache; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $phpfpmconf; ?>';

    include '<?php echo $globalspath; ?>/<?php echo $perlconf; ?>';
<?php
                        }
?>
}

<?php
                    } else {
?>

## No mail map for redirect '<?php echo $redirdomainname; ?>'

<?php
                    }
                }
            }
        }

        $count++;
    }
}
?>

### end - web of '<?php echo $domainname; ?>' - do not remove/modify this line
