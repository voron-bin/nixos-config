{ pkgs, ... }: {
  home.packages = [
    (pkgs.python313.withPackages (ps: with ps; [
      spyder
      numpy
      pandas
      matplotlib
      sympy
      jupyterlab
    ]))
  ];
}
