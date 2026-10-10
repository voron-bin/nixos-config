{ pkgs, ... }: {
  home.packages = [
    (pkgs.python313.withPackages (ps: with ps; [
      numpy
      pandas
      jupyterlab
    ]))
  ];
}
