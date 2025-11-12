.PHONY: help setup test demo clean

help:
	@echo "VPC Project Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  setup    - Install dependencies and configure system"
	@echo "  test     - Run comprehensive test suite"
	@echo "  demo     - Quick demo VPC setup"
	@echo "  clean    - Remove all VPCs and cleanup"
	@echo "  help     - Show this help"

setup:
	@sudo bash setup.sh

test:
	@sudo bash test-vpc.sh

demo:
	@echo "Creating demo VPC..."
	@sudo ./vpcctl create-vpc demo 172.16.0.0/16
	@sudo ./vpcctl add-subnet demo frontend 172.16.1.0/24 public
	@sudo ./vpcctl add-subnet demo backend 172.16.2.0/24 private
	@sudo ./vpcctl list

clean:
	@sudo bash cleanup.sh
