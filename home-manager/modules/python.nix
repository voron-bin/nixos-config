{ pkgs, ... }: {
  home.packages = [
    (pkgs.python313.withPackages (ps: with ps; [
      numpy
      pandas
      matplotlib
      sympy
      jupyterlab
    ]))
  ];
}
