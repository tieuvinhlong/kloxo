<?php

class serverweb extends lxdb
{
	static $__desc = array("", "", "webserver_config");
	static $__desc_nname = array("", "", "webserver_config");
	static $__desc_php_type = array("", "", "php_type");
	static $__desc_secondary_php = array("", "", "secondary_php");

	static $__acdesc_update_edit = array("", "", "config");
	static $__acdesc_show = array("", "", "webserver_config");

	static $__desc_apache_optimize = array("", "", "apache_optimize");

	static $__desc_mysql_convert = array("", "", "mysql_convert");
	static $__desc_mysql_charset = array("", "", "mysql_charset");

	static $__desc_fix_chownchmod = array("", "", "fix_chownchmod");

	static $__desc_php_branch = array("", "", "php_branch");
	static $__desc_php_used = array("", "", "php_used");

	static $__desc_multiple_php_install = array("", "", "multiple_php_install");
	static $__desc_multiple_php_already_installed = array("", "", "multiple_php_already_installed");

	function createShowUpdateform()
	{
		$uflist['edit'] = null;

		$uflist['php_used'] = null;

		$uflist['php_branch'] = null;

		$uflist['multiple_php_install'] = null;

		if (isWebProxyOrApache()) {
			$uflist['php_type'] = null;
			$uflist['apache_optimize'] = null;
		}

		$uflist['mysql_convert'] = null;
		$uflist['fix_chownchmod'] = null;

		return $uflist;
	}

	function preUpdate($subaction, $param)
	{
		// MR -- preUpdate (also preAdd) is new function; process before Update/Add

		// MR -- still any trouble passing value so use this trick
		if (isset($_POST['frm_serverweb_b_multiple_php_install'])) {
			// MR -- $this->multiple_php_install (frm_serverweb_c_multiple_php_install) still empty
			// so, use frm_serverweb_b_multiple_php_install (second multiselect)
			$this->multiple_php_install = $_POST['frm_serverweb_b_multiple_php_install'];
		}

		$join = implode(',', $this->multiple_php_install);

		file_put_contents('/tmp/multiple_php_install.tmp', $join);

		chown('/tmp/multiple_php_install.tmp', 'root:root');
	}

	function updateform($subaction, $param)
	{
		switch($subaction) {
			case "apache_optimize":
				$vlist['apache_optimize'] = array('s', array('---No Change---', 'default', 'optimize'));
				$this->setDefaultValue('apache_optimize', '---No Change---');

				break;
			case "mysql_convert":
				if (getRpmBranchInstalled('mysql') === 'MariaDB-server') {
					$vlist['mysql_convert'] = array('s', array('---No Change---', 'to-myisam', 'to-innodb', 'to-aria'));
				} else {
					$vlist['mysql_convert'] = array('s', array('---No Change---', 'to-myisam', 'to-innodb'));
				}
				
				$this->setDefaultValue('mysql_convert', '---No Change---');

				$vlist['mysql_charset'] = array('s', array('---No Change---', 'utf-8'));

				$this->setDefaultValue('mysql_charset', '---No Change---');

				break;
			case "fix_chownchmod":
				$vlist['fix_chownchmod'] = array('s', array('---No Change---', 'fix-ownership', 'fix-permissions', 'fix-ALL'));

				$this->setDefaultValue('fix_chownchmod', '---No Change---');

				break;
			case "php_type":
				// MR -- remove mod_php on 'php-type' select
				$vlist['php_type'] = array('s', array(
					'mod_php_ruid2', 'mod_php_itk',
					'suphp', 'suphp_event', 'suphp_worker',
					'php-fpm_event', 'php-fpm_worker',
					'fcgid_event', 'fcgid_worker'));
	
				if (!db_get_value("serverweb", "pserver-". $this->syncserver, "php_type")) {
					db_set_default("serverweb", "php_type", "php-fpm_event", 
						"nname = 'pserver-{$this->syncserver}'");
					$this->setDefaultValue('php_type', 'php-fpm_event');
				}

				$vlist['secondary_php'] = array('f', array('on', 'off'));

				if (file_exists("/etc/httpd/conf.d/suphp52.conf")) {
					$this->setDefaultValue('secondary_php', 'on');
				}

				break;
			case "php_branch":
				$a = getRpmBranchListOnList('php');
				$vlist['php_branch'] = array('s', $a);

				$this->setDefaultValue('php_branch', getRpmBranchInstalledOnList('php'));

				break;
			case "multiple_php_install":
				$a = getRpmBranchListOnList('php');

				$c = array();

				foreach ($a as $k => $v) {
					if (strpos($v, 'php_(') !== false) {
						unset($a[$k]);
					} else {
						$b = explode('_(', $v);
						$a[$k] = $b[0];

						if (strpos($a[$k], 'u') !== false) {
							$c[] = str_replace('u', '', $a[$k]);
						}
					}
				}

				$a = array_diff($a, $c);

				foreach($a as $k => $v) {
					$a[$k] = str_replace('u', '', $v) . "m";					
				}

				$d = glob("/opt/*m/usr/bin/php");

				foreach ($d as $k => $v) {
					$e = str_replace('/opt/', '', $v);
					$e = str_replace('/usr/bin/php', '', $e);
					$d[$k] = $e;
				}

				$f = array_diff($a, $d);

				$g = implode(" ", $d);

				$vlist['multiple_php_already_installed'] = array("M", $g);				

				$vlist['multiple_php_install'] = array("U", $a);

				// MR -- not able to 'default' value
			//	$this->setDefaultValue('multiple_php_install', $f);

				break;
			case "php_used":
				$d = glob("/opt/*m/usr/bin/php");

				foreach ($d as $k => $v) {
					$e = str_replace('/opt/', '', $v);
					$e = str_replace('/usr/bin/php', '', $e);
					$d[$k] = $e;

					if ($e === 'php52m') {
						unset($d[$k]);
					}
				}

				$s = '--Use PHP Branch--';

				$d = array_merge(array($s), $d);

				$vlist['php_used'] = array('s', $d);

				foreach ($d as $k => $v) {

					if ($v === $s) {
						$t = "'prog=\"php-fpm\"'";
					} else {
						$t = "'custom_name=\"{$v}\"'";
					}

					exec("cat /etc/rc.d/init.d/php-fpm|grep {$t}", $out);

					if ($out[0]) {
						$this->setDefaultValue('php_used', $v);
						break;
					}
				}

				break;

			default:
				$vlist['__v_button'] = array();

				break;
		}

		return $vlist;
	}

	static function initThisObjectRule($parent, $class, $name = null)
	{
		return $parent->getClName();
	}
}
