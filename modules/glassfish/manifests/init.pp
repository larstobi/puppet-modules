
class glassfish {
	include "packages"
	$pkg = "pkg.mydomain.com"
	$domaindir = "/opt/NSBglassfish/glassfish/domains"

	group { "gfish":
		gid => 201
	}
	user { "gfish":
		uid => 201,
		gid => 201,
		home => "/home/gfish",
		shell => "/bin/bash",
		password => "PASSWORDHASH",
		ensure => role,
		require => Group["gfish"]
	}
	file {
        "/home/gfish":
		    owner => gfish,
		    group => gfish,
		    mode => 755,
		    ensure => directory,
		    require => User["gfish"];

        "/home/gfish/.bashrc":
		    owner => gfish,
		    group => gfish,
		    mode => 755,
		    ensure => present,
            source => "puppet:///modules/glassfish/bashrc",
		    require => File["/home/gfish"];

        "/home/gfish/.bash_profile":
		    owner => gfish,
		    group => gfish,
		    mode => 755,
		    ensure => present,
            source => "puppet:///modules/glassfish/bash_profile",
		    require => File["/home/gfish"];
	}
	file { "/usr/java":
		ensure => "jdk/latest",
		require => Package["SUNWj6rtx"]
	}
	package { "SUNWj6rt":
		adminfile => "/etc/pkgadmin",
		source => "http://$pkg/solaris10/SUNWj6rt-$hardwareisa.pkg"
	}
	package { "SUNWj6rtx":
		adminfile => "/etc/pkgadmin",
		source => "http://$pkg/solaris10/SUNWj6rtx-$hardwareisa.pkg",
		require => Package["SUNWj6rt"]
	}
	package { "SUNWj6dev":
		adminfile => "/etc/pkgadmin",
		source => "http://$pkg/solaris10/SUNWj6dev-$hardwareisa.pkg",
		require => Package["SUNWj6rtx"]
	}
	package { "NSBglassfish":
		adminfile => "/etc/pkgadmin",
		source => "http://$pkg/solaris10/NSBglassfish.pkg",
		require => Package["SUNWj6rtx"],
	}
	file { "/opt/NSBglassfish/glassfish/domains":
		owner => "gfish",
		group => "gfish",
		mode => 755,
		ensure => directory,
		require => Package["NSBglassfish"]
	}
	$passfile = "/home/gfish/.aspass"
	file {
        "$passfile":
		    owner => gfish,
		    group => gfish,
		    mode => 600,
		    source => "puppet:///modules/glassfish/aspasswd";
        "/home/gfish/.asadminpass":
            owner => gfish,
		    group => gfish,
		    mode => 600,
		    source => "puppet:///modules/glassfish/asadminpass";
	}

	define domain(	$passfile,
			$portbase = "4900") {
		$asadmin = "/opt/NSBglassfish/bin/asadmin"
		$svc = "svc:/application/GlassFish/$name"
		$domaindir = "/opt/NSBglassfish/glassfish/domains"

		exec { "create-domain-$name":
			command => "$asadmin --user admin --passwordfile $passfile create-domain --profile cluster --portbase $portbase --savelogin $name",
			path => "/usr/jdk/latest/bin:/usr/bin:/usr/sbin",
			user => "gfish",
			creates => "$domaindir/$name",
			require => [
				File["$passfile"],
				User["gfish"],
				File["/opt/NSBglassfish/glassfish/domains"]
			],
		}
		exec { "create-service-$name":
			command => "$asadmin --passwordfile $passfile create-service $name",
			unless => "svcs $svc",
			require => Exec["create-domain-$name"],
			notify => Exec[
				"modify-start-$name",
				"modify-stop-$name"
			]
		}
		exec { "modify-start-$name":
			command => "svccfg -s $svc setprop start/user = astring: gfish",
			refreshonly => true,
			notify => Exec["refresh-$name"]
		}
		exec { "modify-stop-$name":
			command => "svccfg -s $svc setprop stop/user = astring: gfish",
			refreshonly => true,
			notify => Exec["refresh-$name"]
		}
		exec { "refresh-$name":
			command => "svcadm refresh $svc",
			refreshonly => true
		}
		service { "$svc":
			ensure => running,
			require => [ Exec[
				"refresh-$name",
				"create-service-$name" ],
                         User["gfish"] ],
		}
	}

    define domainconfig($domainenv="") {
        $myenvironment = $domainenv
        $domainname = "${name}"
        $glassfishpath = "/opt/NSBglassfish/glassfish/domains"
        $configfile = "${glassfishpath}/${domainname}/config/domain.xml"

        file {
            $configfile:
                ensure => present,
                owner => "gfish",
                group => "gfish",
                mode => 640,
                content => template("glassfish/${domainname}-domain.xml.erb"),
                require => [ User["gfish"], Group["gfish"] ],
        }
    }

    define domainkeyfile($domainenv) {
        $domainname = "${name}"
        $glassfishpath = "/opt/NSBglassfish/glassfish/domains"
        $configfile = "${glassfishpath}/${domainname}/config/keyfile"

        file {
            "keyfile":
                ensure => present,
                owner => "gfish",
                group => "gfish",
                mode => 600,
                path => "${configfile}",
                source => "puppet:///modules/glassfish/${name}-${domainenv}-keyfile";
        }       
    }

    define wildcard_mydomain_com_cert {
        $glassfishpath = "/opt/NSBglassfish/glassfish/domains"
        $certificate = "wildcard.mydomain.com.p12"
        $certfile = "${glassfishpath}/${name}/config/${certificate}"
        file {
            $certfile:
                ensure => present,
                owner => "gfish",
                group => "gfish",
                mode => 400,
                source => "puppet:///modules/glassfish/${certificate}",
                require => [ User["gfish"], Group["gfish"] ],
        }
    }
}
import "*.pp"
