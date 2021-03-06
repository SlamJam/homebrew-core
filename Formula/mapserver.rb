class Mapserver < Formula
  desc "Publish spatial data and interactive mapping apps to the web"
  homepage "http://mapserver.org/"
  url "http://download.osgeo.org/mapserver/mapserver-6.4.3.tar.gz"
  sha256 "1f432d4b44e7a0e4e9ce883b02c91c9a66314123028eebb0415144903b8de9c2"

  bottle do
    cellar :any
    sha256 "76b78fec6ddef503c68bc791259dba5e19afec1a0bca7bb0e9c70f06e7e01e33" => :el_capitan
    sha256 "fa018ad2b14492f50e0b6a4ed50212201c016bb0f35baf81031062fbe5a337e2" => :yosemite
    sha256 "a2c6ecfd38837a5a9287fdb0fb729ee4acbfb1d2df5a5e47dff8905cb982e237" => :mavericks
  end

  option "with-fastcgi", "Build with fastcgi support"
  option "with-geos", "Build support for GEOS spatial operations"
  option "with-php", "Build PHP MapScript module"
  option "with-postgresql", "Build support for PostgreSQL as a data source"

  env :userpaths

  depends_on "pkg-config" => :build
  depends_on "cmake" => :build
  depends_on "swig" => :build
  depends_on "freetype"
  depends_on "libpng"
  depends_on "giflib"
  depends_on "gd"
  depends_on "proj"
  depends_on "gdal"
  depends_on "geos" => :optional
  depends_on "postgresql" => :optional unless MacOS.version >= :lion
  depends_on "cairo" => :optional
  depends_on "fribidi" => :optional
  depends_on "fcgi" if build.with? "fastcgi"

  def install
    args = std_cmake_args
    args << "-DWITH_PROJ=ON" << "-DWITH_GDAL=ON" << "-DWITH_OGR=ON" << "-DWITH_WFS=ON"

    # Install within our sandbox.
    inreplace "mapscript/php/CMakeLists.txt", "${PHP5_EXTENSION_DIR}", lib/"php/extensions"
    args << "-DWITH_PHP=ON" if build.with? "php"

    # Install within our sandbox.
    inreplace "mapscript/python/CMakeLists.txt" do |s|
      s.gsub! "${PYTHON_SITE_PACKAGES}", lib/"python2.7/site-packages"
      s.gsub! "${PYTHON_LIBRARIES}", "-Wl,-undefined,dynamic_lookup"
    end
    args << "-DWITH_PYTHON=ON"
    # Using rpath on python module seems to cause problems if you attempt to
    # import it with an interpreter it wasn't built against.
    # 2): Library not loaded: @rpath/libmapserver.1.dylib
    args << "-DCMAKE_SKIP_RPATH=ON"

    # All of the below are on by default so need
    # explicitly disabling if not requested.
    if build.with? "geos"
      args << "-DWITH_GEOS=ON"
    else
      args << "-DWITH_GEOS=OFF"
    end

    if build.with? "cairo"
      args << "-WITH_CAIRO=ON"
    else
      args << "-DWITH_CAIRO=OFF"
    end

    if build.with? "postgresql"
      args << "-DWITH_POSTGIS=ON"
    else
      args << "-DWITH_POSTGIS=OFF"
    end

    if build.with? "fastcgi"
      args << "-DWITH_FCGI=ON"
    else
      args << "-DWITH_FCGI=OFF"
    end

    if build.with? "fribidi"
      args << "-DWITH_FRIBIDI=ON"
    else
      args << "-DWITH_FRIBIDI=OFF"
    end

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end

  def caveats; <<-EOS.undent
    The Mapserver CGI executable is #{opt_bin}/mapserv

    If you built the PHP option:
      * Add the following line to php.ini:
        extension="#{opt_lib}/php/extensions/php_mapscript.so"
      * Execute "php -m"
      * You should see MapScript in the module list
    EOS
  end

  test do
    system "#{bin}/legend"
  end
end
