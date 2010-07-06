class glassfish::full inherits glassfish {
	domain { "full":
		passfile => $passfile,
		portbase => "5000"
	}

    wildcard_nsb_no_cert {
        "full":
    }

    $fullpath = "/opt/NSBglassfish/glassfish/domains/full"

    file {
        "sqljdbc4.jar":
            ensure => present,
            owner => "gfish",
            group => "gfish",
            mode => 440,
            path => "${fullpath}/lib/sqljdbc4.jar",
            source => "puppet:///modules/glassfish/sqljdbc4.jar",
            require => Domain["full"];
    }
}

class glassfish::full::staging inherits glassfish {
    domainconfig {
        "full":
            domainenv => "staging",
    }
    domainkeyfile {
        "full":
            domainenv => "staging",
    }
}

class glassfish::full::production inherits glassfish {
    domainconfig {
        "full":
            domainenv => "prod",
    }
    domainkeyfile {
        "full":
            domainenv => "prod",
    }
}
