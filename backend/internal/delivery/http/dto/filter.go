package dto

type MenuFilterResponse struct {
	Menus  []MenuResponse `json:"menus"`
	Source string         `json:"source"` // "personal" | "global"
}
