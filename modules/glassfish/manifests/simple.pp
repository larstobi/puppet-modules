class glassfish::simple inherits glassfish {
	domain { "simple":
		passfile => $passfile,
		portbase => "4800"
	}
}
