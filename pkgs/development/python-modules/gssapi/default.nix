{ stdenv
, lib
, buildPythonPackage
, pythonOlder
, fetchFromGitHub
, six
, decorator
, nose
, krb5
, GSS
, parameterized
, shouldbe
, cython
, python
, k5test
}:

buildPythonPackage rec {
  pname = "gssapi";
  version = "1.7.3";
  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "pythongssapi";
    repo = "python-${pname}";
    rev = "v${version}";
    sha256 = "sha256-/1YOnG6sCP8G8J3K2/RycTC95rXW9M+U3Mjz4GCt13s=";
  };

  # It's used to locate headers
  postPatch = ''
    substituteInPlace setup.py \
      --replace 'get_output(f"{kc} gssapi --prefix")' '"${lib.getDev krb5}"'
  '';

  nativeBuildInputs = [
    cython
    krb5
  ];

  propagatedBuildInputs =  [
    decorator
    six
  ];

  buildInputs = lib.optionals stdenv.isDarwin [
    GSS
  ];

  checkInputs = [
    k5test
    nose
    parameterized
    shouldbe
    six
  ];

  doCheck = pythonOlder "3.8"  # `shouldbe` not available
    && !stdenv.isDarwin;  # many failures on darwin

  # skip tests which fail possibly due to be an upstream issue (see
  # https://github.com/pythongssapi/python-gssapi/issues/220)
  checkPhase = ''
    # some tests don't respond to being disabled through nosetests -x
    echo $'\ndel CredsTestCase.test_add_with_impersonate' >> gssapi/tests/test_high_level.py
    echo $'\ndel TestBaseUtilities.test_acquire_creds_impersonate_name' >> gssapi/tests/test_raw.py
    echo $'\ndel TestBaseUtilities.test_add_cred_impersonate_name' >> gssapi/tests/test_raw.py

    export PYTHONPATH="$out/${python.sitePackages}:$PYTHONPATH"
    nosetests -e 'ext_test_\d.*'
  '';
  pythonImportsCheck = [ "gssapi" ];

  meta = with lib; {
    homepage = "https://pypi.python.org/pypi/gssapi";
    description = "Python GSSAPI Wrapper";
    license = licenses.mit;
  };
}
