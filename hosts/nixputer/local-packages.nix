{ pkgs, ... }: {
	environment.systemPackages = with pkgs; [
		# purely an option if I want a hostname to have different packages than is standard

	];
}
