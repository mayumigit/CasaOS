package v2

import (
	"net/http"
	"github.com/labstack/echo/v4"
	"github.com/mayumigit/CasaOS/service"
	"github.com/mayumigit/CasaOS/codegen"
	"fmt"
)

func (c *CasaOS) GetWiFiStatus(ctx echo.Context) error {
	fmt.Println("🍀 GetWiFiStatus was called!")
	status, err := service.MyService.Wifi().WifiStatus()
	if err != nil {
		message := err.Error()
		return ctx.JSON(http.StatusInternalServerError, codegen.ResponseInternalServerError{
			Message: &message,
		})
	}
	fmt.Println("*****")
	fmt.Println(status)
	return ctx.JSON(http.StatusOK, status)
}

func (c *CasaOS) SetWiFiConfig(ctx echo.Context) error {
	var req codegen.WiFiConfig
	if err := ctx.Bind(&req); err != nil {
		return ctx.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	go func(ssid, password string) {
		err := service.MyService.Wifi().SetupWiFi(ssid, password)
		if err != nil {
			// ❗ ログなどで内部的に把握だけしておく（失敗通知は今はしない）
			fmt.Printf("⚠️ WiFi setup failed in background: %v\n", err)
		}
	}(*req.Ssid, *req.Password)

	return ctx.JSON(http.StatusOK, map[string]string{"status": "accepted"})
}
func (c *CasaOS) SetWiFiAPMode(ctx echo.Context) error {
	fmt.Println("*****")
	fmt.Println("⚠️SetWiFiApmode!!")
	err := service.MyService.Wifi().SetupAPMode()
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}
	return ctx.JSON(http.StatusOK, map[string]string{"status": "ok"})
}
