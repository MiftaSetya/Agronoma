<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_plants', function (Blueprint $table) {
            $table->enum('status', ['active', 'archived', 'harvested', 'failed'])
                ->default('active')
                ->change();
        });
    }

    public function down(): void
    {
        Schema::table('user_plants', function (Blueprint $table) {
            $table->enum('status', ['active', 'archived', 'failed'])
                ->default('active')
                ->change();
        });
    }
};
