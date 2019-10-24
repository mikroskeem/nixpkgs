{ buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "glob2";
  version = "0.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "85c3dbd07c8aa26d63d7aacee34fa86e9a91a3873bc30bf62ec46e531f92ab8c";
  };
}
