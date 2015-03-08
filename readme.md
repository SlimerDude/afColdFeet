#Cold Feet v1.3.2
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v1.3.2](http://img.shields.io/badge/pod-v1.3.2-yellow.svg)](http://www.fantomfactory.org/pods/afColdFeet)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

`Cold Feet` is an asset caching strategy for your [Bed App](http://www.fantomfactory.org/pods/afBedSheet).

- Tired of telling clients to clear their browser cache to pick up the latest CSS and Javascript changes?
- Don't want lame browser cache busting because you need network performance?
- Then get `Cold Feet`!

## Install

Install `Cold Feet` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afColdFeet

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afColdFeet 1.3"]

## Documentation

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afColdFeet/).

## Quick Start

1. Create a text file called `Example.fan`:

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
        class AppModule {
            @Contribute { serviceType=Routes# }
            static Void contributeRoutes(Configuration conf) {
                conf.add(Route(`/`, Example#coldFeetUrls))
            }
        }
        
        class Main {
            Int main() {
                BedSheetBuilder(AppModule#.qname).startWisp(8080)
            }
        }


2. Run `Example.fan` as a Fantom script from the command line. This starts the [BedSheet](http://www.fantomfactory.org/pods/afBedSheet) app server:

        C:\> fan Example.fan
           ___    __                 _____        _
          / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
         / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
        /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                   Alien-Factory BedSheet v1.4.8, IoC v2.0.6 /___/
        
        IoC Registry built in 612ms and started up in 104ms
        
        Bed App 'Unknown' listening on http://localhost:8080/


3. Visit `http://localhost:8080/`

        .  Normal URL: /pods/icons/x256/flux.png
        Cold Feet URL: /coldFeet/infYBQ==/pods/icons/x256/flux.png



## Usage

Contribute your asset directories to the BedSheet [FileHandler](http://repo.status302.com/doc/afBedSheet/FileHandler.html) service as usual, but rather than hard-coding the asset URLs, let the `FileHandler` service generate them for you.

`Cold Feet` invisibly instruments the `FileHandler` service to add a caching strategy to the generated client URLs. An asset URL such as ``/css/myStyles.css`` magically becomes a `Cold Feet` URL like ``/coldFeet/XXXX/css/myStyles.css``, where:

- `/coldFeet` is a prefix used to identify the URL on incoming requests.
- `/XXXX` is a digest, generated by Cold Feet, that changes when the asset content changes.

When a request is made for the asset using the modified URL, `Cold Feet` intercepts the request using [BedSheet](http://www.fantomfactory.org/pods/afBedSheet) middleware and serves up the file.

`Cold Feet` lets the browser aggressively cache these files by setting a far-future expiration header on it (1 year by default). Note this expiration header is only enabled in production; see [IoC Env](http://www.fantomfactory.org/pods/afIocEnv).

If during that 1 year the asset is modified then the `Cold Feet` URL will change, just as the `XXXX` digest changes. This forces the browser to download the new asset.

The smart ones amongst you will be asking, *"But what if the browser requests an old asset URL?"* Simple, `Cold Feet` recognises outdated URLs and responds with a `308 - Moved Permanently` redirecting the browser to the new asset URL.

## What Usage?

Because `Cold Feet` works in the background, invisibly advising the `FileHandler` and `PodHandler` services, there is no *Cold Feet Usage* per se. Just add `Cold Feet` as a project dependency and optionally configure a digest.

Then use `FileHandler` and `PodHandler` to generate client URLs to your files, and use them your web pages.

You may also prevent `ColdFeet` from altering subsets of URLs by contributing regular expressions to `UrlExclusions`. Example, to make `ColdFeet` ignore all files in the directory `images/`:

    @Contribute { serviceType=UrlExclusions# }
    static Void contributeUrlExclusions(Configuration config) {
        config.add("^/images/".toRegex)
    }

## Digest Strategies

### Adler-32

This is the default strategy used by `Cold Feet`. It calculates a digest with the [Adler-32](http://en.wikipedia.org/wiki/Adler32) checksum algorithm. The checksum is then Base-64 encoded using the [URL and filename safe alphabet](http://tools.ietf.org/html/rfc4648#section-5).

The Adler-32 checksum was designed for speed and created for use in the [zlib](http://en.wikipedia.org/wiki/Zlib) compression library which makes it an ideal fit for an asset digest.

Note that if your CSS file has a relative URL in it, such as:

    .pretty-div {
        background-image: url(../images/pretty.png);
    }

Then, under Adler-32 and path transformations, `pretty.png` will be served under the wrong digest. This is because if your CSS file is served under:

    /coldFeet/x9x9x9/css/styles.css

The browser will resolve `pretty.png` to be under the same digest path:

    /coldFeet/x9x9x9/css/../images/pretty.png

This won't do any harm, as `Cold Feet` will simply redirect the browser to the correct URL, but the redirect is a wasted round trip. As each redirect creates a warning, monitor your logs to find any missed relative URLs and correct as necessary. If there are many, you may wish to preprocess your CSS files to generate the Cold Feet URLs before serving.

### App Version

This simple strategy ignores the asset file in question and instead returns the application's pod version. Thus, when a new application is deployed (with an new version), clients will re-download all the assets.

When not in production mode, the digest defaults to a random string.

To use, override the default digest strategy in your `AppModule`:

```
class AppModule {
    @Override
    static DigestStrategy overrideDigestStrategy() {
        AppVersionDigest()
    }
}
```

### Fixed Value

Use this strategy in testing. It returns a fixed / constant value each and every time.

To use, override the default digest strategy in your `AppModule`:

```
class AppModule {
    @Override
    static DigestStrategy overrideDigestStrategy() {
        FixedValueDigest("XXX")
    }
}
```

## URL Transforming

You may customise the way URLs are transformed to and from ColdFeet URLs. To do so, implement and contribute a [UrlTransformer](http://repo.status302.com/doc/afColdFeet/UrlTransformer.html).

### Path Transformer

This is the default URL transformation as detailed in the rest of the documentation. The ColdFeet prefix and digest are prepended to the URL as path segments:

    /css/myStyle.css  --> /coldFeet/XXXX/css/myStyle.css

### Name Transformer

If you don't like the idea of Cold Feet transforming the paths of your URLs, try transforming the name instead!

The [NameTransformer](http://repo.status302.com/doc/afColdFeet/NameTransformer.html) inserts the ColdFeet prefix and digest into the name part of the URL, leaving the path alone:

    /css/myStyle.css  --> /css/myStyle.coldFeet.XXXX.css

To use, override the default URL transformer in your `AppModule`:

```
class AppModule {
    @Override
    static UrlTransformer overrideUrlTransformer(Registry registry) {
        registry.autobuild(NameTransformer#)
    }
}
```

