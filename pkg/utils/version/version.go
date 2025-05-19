/*
 * @Author: LinkLeong link@icewhale.com
 * @Date: 2022-05-13 18:15:46
 * @LastEditors: LinkLeong
 * @LastEditTime: 2022-07-21 15:27:53
 * @FilePath: /CasaOS/pkg/utils/version/version.go
 * @Description:
 * @Website: https://www.casaos.io
 * Copyright (c) 2022 by icewhale, All Rights Reserved.
 */
package version

import (
	"strconv"
	"strings"
	"fmt"
	"github.com/mayumigit/CasaOS/common"
	"github.com/mayumigit/CasaOS/model"
)
func ParseFullVersion(ver string) ([]int, error) {
	// 例: "v0.4.18-cs1.0.0"
	ver = strings.TrimPrefix(ver, "v")

	parts := strings.Split(ver, "-cs")
	if len(parts) != 2 {
		return nil, fmt.Errorf("invalid version format")
	}

	upstreamParts := strings.Split(parts[0], ".")
	customParts := strings.Split(parts[1], ".")

	if len(upstreamParts) != 3 || len(customParts) != 3 {
		return nil, fmt.Errorf("version must have 3 upstream and 3 custom segments")
	}

	result := []int{}
	for _, s := range append(upstreamParts, customParts...) {
		n, err := strconv.Atoi(s)
		if err != nil {
			return nil, err
		}
		result = append(result, n)
	}
	return result, nil
}

func IsNeedUpdate(version model.Version) (bool, model.Version) {

	v1 := strings.Split(version.Version, ".")

	v2 := strings.Split(common.VERSION, ".")

	for len(v1) < len(v2) {
		v1 = append(v1, "0")
	}
	for len(v2) < len(v1) {
		v2 = append(v2, "0")
	}
	for i := 0; i < len(v1); i++ {
		a, _ := strconv.Atoi(v1[i])
		b, _ := strconv.Atoi(v2[i])
		if a > b {
			return true, version
		}
		if a < b {
			return false, version
		}
	}
	return false, version
}

func IsNewerVersion(remote model.Version) (bool, error) {
	//CassetteOS Customize from IsNeedUpdate
	rv, err := ParseFullVersion(remote.Version)
	if err != nil {
		return false, err
	}
	lv, err := ParseFullVersion(common.VERSION)
	if err != nil {
		return false, err
	}
	for i := 0; i < len(rv); i++ {
		if rv[i] > lv[i] {
			return true, nil
		}
		if rv[i] < lv[i] {
			return false, nil
		}
	}
	return false, nil 
}