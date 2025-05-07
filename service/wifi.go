package service

import (
	"github.com/mayumigit/CasaOS-Common/utils/command"
	"github.com/mayumigit/CasaOS/pkg/config"
	"os/exec"
	"strings"
	//"errors"
	"fmt"
)
type WifiStatus struct {
	Mode      string `json:"mode"`
	SSID      string `json:"ssid"`
	IPAddress string `json:"ip_address"`
}
type WifiService interface {
	WifiStatus() (*WifiStatus, error) 
	SetupWiFi(ssid string, password string) error
	SetupAPMode() error
}

type wifi struct{}

func (s *wifi) WifiStatus()(*WifiStatus, error)  {
	interfaceName, err := getWifiInterface()
	if err != nil {
		return nil, err
	}

	if isServiceActive("hostapd") {
		ip, err := getIPAddress(interfaceName)
		if err != nil {
			return nil, err
		}
		return &WifiStatus{
			Mode:		"ap",
			SSID:		"",
			IPAddress:	ip,
		}, nil
	} else if isServiceActive("wpa_supplicant@" + interfaceName) {
		ip, err := getIPAddress(interfaceName)
		if err != nil {
			return nil, err
		}
		ssid, err := getSSID(interfaceName)
		if err != nil {
			return nil, err
		}
		return &WifiStatus{
			Mode:      "client",
			SSID:      ssid,
			IPAddress: ip,
		}, nil
	}

	return &WifiStatus{Mode: "unknown"}, nil
}

func (s *wifi) SetupWiFi(ssid string, password string) error {
	output, err := command.OnlyExec("source " + config.AppInfo.ShellPath + "/switch-wifi-mode.sh" + " client "  + ssid + " " + password);

	if exitErr, ok := err.(*exec.ExitError); ok {
		if exitErr.ExitCode() == 1 {
			return fmt.Errorf("wifi setup failed: %s", string(output))
		} else {
			return fmt.Errorf("unexpected exit code: %d\nOutput: %s", exitErr.ExitCode(), string(output))
		}
	} else if err != nil {
		return fmt.Errorf("execution failed: %v", err)
	}
	return nil
}
func (s *wifi) SetupAPMode() error {
	output, err := command.OnlyExec("source " + config.AppInfo.ShellPath + "/switch-wifi-mode.sh" + " ap");
	if exitErr, ok := err.(*exec.ExitError); ok {
		if exitErr.ExitCode() == 1 {
			return fmt.Errorf("AP mode setup failed: %s", string(output))
		} else {
			return fmt.Errorf("unexpected exit code: %d\nOutput: %s", exitErr.ExitCode(), string(output))
		}
	} else if err != nil {
		return fmt.Errorf("execution failed: %v", err)
	}
	return nil

}

func NewWifiService() WifiService {
	return &wifi{}
}
// getWifiInterface returns the name of the first Wi-Fi interface found using `iw dev`.
func getWifiInterface() (string, error) {
	cmd := exec.Command("iw", "dev")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "Interface") {
			parts := strings.Fields(line)
			if len(parts) == 2 {
				return parts[1], nil
			}
		}
	}

	return "", nil // or an error if you want to fail when not found
}
func isServiceActive(service string) bool {
	cmd := exec.Command("systemctl", "is-active", "--quiet", service)
	err := cmd.Run()
	return err == nil
}
func getIPAddress(interfaceName string) (string, error) {
	cmd := exec.Command("ip", "addr", "show", interfaceName)
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "inet ") {
			fields := strings.Fields(line)
			if len(fields) > 1 {
				// フォーマット: "inet 192.168.0.123/24"
				ip := strings.Split(fields[1], "/")[0]
				return ip, nil
			}
		}
	}

	return "", nil
}
func getSSID(interfaceName string) (string, error) {
	confPath := "/etc/wpa_supplicant/wpa_supplicant-" + interfaceName + ".conf"

	cmd := exec.Command("grep", "ssid=", confPath)
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}

	line := strings.TrimSpace(string(output))
	// フォーマット: ssid="MyNetwork"
	parts := strings.Split(line, "\"")
	if len(parts) >= 2 {
		return parts[1], nil
	}

	return "", nil
}
