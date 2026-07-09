<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    // GET /api/settings
    public function index()
    {
        $settings = Setting::all()->groupBy('group');
        return response()->json($settings);
    }

    // GET /api/settings/flat — simple key=>value object
    public function flat()
    {
        return response()->json(Setting::pluck('value', 'key'));
    }

    // PUT /api/settings  — bulk update
    public function bulkUpdate(Request $request)
    {
        $request->validate(['settings' => 'required|array']);

        foreach ($request->settings as $key => $value) {
            Setting::set($key, $value);
        }

        return response()->json(['message' => 'Pengaturan berhasil disimpan.']);
    }

    // PUT /api/settings/{key}
    public function update(Request $request, string $key)
    {
        $request->validate(['value' => 'required']);
        Setting::set($key, $request->value);
        return response()->json(['key' => $key, 'value' => $request->value]);
    }
}
