class packages {
        file { "/etc/pkgadmin":
                owner => root,
                group => root,
                mode => 444,
                source => "puppet:///modules/packages/pkgadmin"
        }
}
