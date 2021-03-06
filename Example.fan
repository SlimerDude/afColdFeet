using afIoc
using afBedSheet
using afColdFeet

class Example {
    @Inject PodHandler? podHandler

    Text coldFeetUrls() {
        asset := podHandler.fromPodResource(`fan://icons/x256/flux.png`)
        msg   := "   Normal URL: ${asset.localUrl} \n"
        msg   += "Cold Feet URL: ${asset.clientUrl}\n"
        return Text.fromPlain(msg)
    }
}

@SubModule { modules=[ColdFeetModule#] }
const class AppModule {
    @Contribute { serviceType=Routes# }
    Void contributeRoutes(Configuration conf) {
        conf.add(Route(`/`, Example#coldFeetUrls))
    }
}

class Main {
    Int main() {
        BedSheetBuilder(AppModule#.qname).startWisp(8080)
    }
}
